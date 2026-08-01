import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants/ai_config.dart';

/// How confident the AI is about a single transcribed line.
enum ScanConfidence { high, medium, low }

extension ScanConfidenceX on ScanConfidence {
  String get label {
    switch (this) {
      case ScanConfidence.high:
        return 'Looks clear';
      case ScanConfidence.medium:
        return 'Mostly clear';
      case ScanConfidence.low:
        return 'Double check';
    }
  }
}

/// One medicine line item read off the prescription photo.
class PrescriptionScanItem {
  final String medicine;
  final String? dosage;
  final String? quantity;
  final String rawText;
  final ScanConfidence confidence;
  final bool catalogMatch;

  /// Other medically-plausible readings of the same handwritten
  /// fragment, when the model genuinely can't settle on one (e.g. the
  /// strokes could be "Losartan" or "Lorazepam"). Empty when the model
  /// is confident. Lets the review UI offer these as one-tap swaps
  /// instead of forcing the patient to guess-retype a drug name.
  final List<String> alternates;

  const PrescriptionScanItem({
    required this.medicine,
    required this.rawText,
    required this.confidence,
    required this.catalogMatch,
    this.dosage,
    this.quantity,
    this.alternates = const [],
  });

  factory PrescriptionScanItem.fromJson(Map<String, dynamic> json) {
    String? clean(dynamic v) {
      final s = v?.toString().trim();
      if (s == null || s.isEmpty || s.toLowerCase() == 'null') return null;
      return s;
    }

    final altJson = json['alternates'] as List<dynamic>? ?? const [];
    final medicine = clean(json['medicine']) ?? '';
    final alternates = altJson
        .map((a) => clean(a) ?? '')
        .where((a) => a.isNotEmpty && a.toLowerCase() != medicine.toLowerCase())
        .toSet()
        .toList();

    return PrescriptionScanItem(
      medicine: medicine,
      dosage: clean(json['dosage']),
      quantity: clean(json['quantity']),
      rawText: clean(json['raw']) ?? '',
      confidence: parseScanConfidence(json['confidence']),
      catalogMatch: json['catalog_match'] == true,
      alternates: alternates,
    );
  }

  /// One line suitable for the editable order text box, e.g.
  /// "Amoxicillin 500mg — x2 boxes".
  String toOrderLine() {
    final base = [medicine, if (dosage != null) dosage].join(' ').trim();
    return quantity != null ? '$base — $quantity' : base;
  }
}

/// Result of reading one prescription photo.
class PrescriptionScanResult {
  final List<PrescriptionScanItem> items;
  final String transcript;
  final String? unclearNotes;
  final ScanConfidence overallConfidence;

  const PrescriptionScanResult({
    required this.items,
    required this.transcript,
    required this.overallConfidence,
    this.unclearNotes,
  });

  bool get hasLowConfidence =>
      overallConfidence == ScanConfidence.low ||
      items.any((i) => i.confidence == ScanConfidence.low);
}

ScanConfidence parseScanConfidence(dynamic v) {
  switch (v?.toString().toLowerCase()) {
    case 'high':
      return ScanConfidence.high;
    case 'low':
      return ScanConfidence.low;
    default:
      return ScanConfidence.medium;
  }
}

/// Uses Gemini's multimodal vision model to read handwritten
/// prescriptions far more reliably than plain on-device OCR.
///
/// Plain character-recognition OCR (the google_mlkit_text_recognition
/// path used elsewhere in this screen) only matches letter *shapes*.
/// That works fine for a printed label but has no real strategy for
/// the fast, idiosyncratic scrawl doctors write drug names and dosages
/// in — it tends to fail exactly where getting it right matters most.
///
/// This service instead asks a vision-capable language model to read
/// the photo the way a pharmacist would: combining the shapes on the
/// page with real-world knowledge of drug-name spelling, common dosage
/// units, and standard prescription abbreviations (mg, mL, od/bd/tds,
/// etc.) to resolve ambiguous strokes, and — since a wrong "best
/// guess" on a prescription is more dangerous than an admitted
/// uncertainty — to honestly flag any line it isn't sure about rather
/// than silently guessing. It's a reading aid only: results are always
/// shown to the customer to review/edit, and a human pharmacist still
/// reviews the submitted request before anything is fulfilled.
class PrescriptionVisionService {
  PrescriptionVisionService._();

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Caps how many catalog names get sent so a large inventory doesn't
  /// blow up prompt size/latency.
  static const int _maxCatalogNames = 200;

  static String _buildPrompt(List<String> catalogNames) {
    final catalogBlock = catalogNames.isEmpty
        ? ''
        : '\n\nThis pharmacy currently stocks these medicines. Use this '
            'list only to help resolve messy handwriting to the correct '
            'spelling when a word plausibly matches one of them — do '
            'not force a match if the handwriting clearly says '
            'something else, and set "catalog_match" accordingly:\n'
            '${catalogNames.take(_maxCatalogNames).join(', ')}';

    return '''
You are helping a pharmacy app read a photo of a paper prescription.
These are very often handwritten by doctors in fast, messy, or
inconsistent handwriting — rushed cursive, squashed letters, strokes
that trail off, inconsistent letter height, and words that overlap
the dosage line. Read the image the way an experienced pharmacist
reading doctors' handwriting would, not the way a generic
character-shape OCR engine would:

- Combine the letter shapes with your knowledge of real drug names,
  common dosage strengths, and standard prescription abbreviations
  (mg, mL, mcg, IU, tab, cap, syr, od/bd/tds/qid, prn, stat) to figure
  out the most medically plausible reading — not just the most literal
  stroke shape. A pharmacist reads doctor scrawl by recognizing the
  *word*, not by parsing each letter in isolation, so weigh whole-word
  plausibility against a real drug/dosage vocabulary over any single
  ambiguous stroke.
- Use the shape of the whole word (length, ascenders/descenders,
  double letters) plus context (what dosage/frequency follows it,
  what condition it's typically prescribed for) to disambiguate, the
  same way a pharmacist cross-checks a scrawled name against what
  would actually make sense on that line.
- Watch for the specific confusions that trip up both careless humans
  and plain OCR on medical handwriting: 1/7, 0/6/8, 5/S, mg/mcg/mL,
  b.i.d./t.i.d./q.i.d. cross-strokes, trailing "-in"/"-ine"/"-one"
  drug-name suffixes, and doubled letters that look single in a fast
  hand. Numbers in dosages and frequencies matter medically, so read
  them especially carefully and flag any that aren't fully certain.
- If a word could plausibly be more than one real drug name, do not
  silently commit to a single guess: put your best reading in
  "medicine", and list the other plausible real drug names in
  "alternates" (most likely first, max 3, empty array if you're not
  genuinely torn between options).
- Split the prescription into individual medicine line items.
- Judge your own confidence honestly per item: "high" only if you are
  genuinely sure, "medium" if plausible but a stroke or two is
  ambiguous, "low" if you are largely guessing. Never mark something
  "high" just because you were able to produce *some* reading — an
  illegible scrawl that you had to force into a plausible-looking drug
  name is "low", not "high".
- If any part of the image is illegible, blurry, cropped, or the
  photo quality itself is the limiting factor (poor lighting, glare,
  out of focus, at an angle), say so plainly in "unclear_notes"
  instead of inventing text to fill the gap.
- You are only transcribing what is written — do not add, correct,
  suggest, or comment on the medical content, dosing, or suitability
  of anything you read.
$catalogBlock

Respond with ONLY minified JSON, no markdown fences, no commentary,
matching exactly this shape:
{"transcript":"full best-effort plain text reading of the whole image","items":[{"medicine":"drug name","dosage":"e.g. 500mg, or null","quantity":"e.g. x2 boxes, or null","raw":"the literal handwritten fragment this line came from","confidence":"high|medium|low","catalog_match":true|false,"alternates":["other plausible drug name",""]}],"unclear_notes":"short plain-English note on anything illegible/ambiguous/poor-quality, or null if none","overall_confidence":"high|medium|low"}
''';
  }

  /// Reads [imageFile] and returns a structured, confidence-scored
  /// transcription. Throws on network/API errors or if Gemini isn't
  /// configured — callers should fall back to plain on-device OCR in
  /// that case (e.g. no internet connection).
  static Future<PrescriptionScanResult> analyze({
    required File imageFile,
    List<String> catalogDrugNames = const [],
  }) async {
    if (!AiConfig.isConfigured) {
      throw StateError('Gemini API key is not set.');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final lowerPath = imageFile.path.toLowerCase();
    final mimeType = lowerPath.endsWith('.png') ? 'image/png' : 'image/jpeg';

    final uri = Uri.parse('$_baseUrl/${AiConfig.model}:generateContent');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': AiConfig.apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': _buildPrompt(catalogDrugNames)},
                  {
                    'inline_data': {
                      'mime_type': mimeType,
                      'data': base64Image,
                    },
                  },
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.15,
              'maxOutputTokens': 1536,
              'responseMimeType': 'application/json',
            },
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API error (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      final blockReason = data['promptFeedback']?['blockReason'];
      throw Exception(
        blockReason != null
            ? 'Gemini blocked this response ($blockReason).'
            : 'Gemini returned no response.',
      );
    }

    final parts =
        (candidates.first['content']?['parts'] as List<dynamic>?) ?? [];
    final text = parts.map((p) => p['text']?.toString() ?? '').join().trim();
    if (text.isEmpty) {
      throw Exception('Gemini returned an empty response.');
    }

    // Defensive: strip markdown fences in case the model adds them
    // despite responseMimeType being set.
    final cleaned = text
        .replaceAll(RegExp(r'^```json', multiLine: true), '')
        .replaceAll(RegExp(r'^```', multiLine: true), '')
        .replaceAll(RegExp(r'```$', multiLine: true), '')
        .trim();

    final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

    final itemsJson = parsed['items'] as List<dynamic>? ?? [];
    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(PrescriptionScanItem.fromJson)
        .where((i) => i.medicine.isNotEmpty)
        .toList();

    final unclear = parsed['unclear_notes']?.toString().trim();

    return PrescriptionScanResult(
      items: items,
      transcript: (parsed['transcript']?.toString() ?? '').trim(),
      unclearNotes:
          (unclear == null || unclear.isEmpty || unclear.toLowerCase() == 'null')
              ? null
              : unclear,
      overallConfidence: parseScanConfidence(parsed['overall_confidence']),
    );
  }
}
