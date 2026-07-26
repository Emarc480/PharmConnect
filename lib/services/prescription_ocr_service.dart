import 'dart:io';
import 'dart:math' as math;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/drug.dart';

/// A single candidate drug match suggested from OCR'd prescription
/// text, with a 0–1 confidence score so the UI can show *how sure*
/// the match is rather than presenting it as certain.
class DrugMatch {
  final Drug drug;
  final double score;
  const DrugMatch({required this.drug, required this.score});
}

/// Runs on-device text recognition on a photo of a prescription, then
/// fuzzy-matches the (often messy, handwritten) result against the
/// known drug catalog.
///
/// Deliberately NOT trying to parse dosage/frequency out of the text
/// — handwriting recognition on medical shorthand is a genuinely hard
/// problem, and getting a dosage wrong is a real safety issue, not
/// just a UX one. This only suggests which catalog drugs the
/// handwriting might refer to; a human (the customer, then the
/// reviewing pharmacist) always confirms before anything is
/// submitted or fulfilled.
class PrescriptionOcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  /// Matches the extracted text against [catalog], returning the top
  /// [maxResults] drugs whose name most resembles some part of the
  /// text, above [minScore] similarity (0–1). Returns an empty list
  /// if nothing clears the bar — showing nothing is better than
  /// showing a confidently wrong guess.
  List<DrugMatch> matchDrugs(
    String ocrText,
    List<Drug> catalog, {
    int maxResults = 5,
    double minScore = 0.6,
  }) {
    final words = ocrText
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return [];

    final matches = <DrugMatch>[];

    for (final drug in catalog) {
      final drugWords = drug.name.toLowerCase().split(RegExp(r'\s+'));
      double bestScore = 0;

      // Slide a window the same length as the drug name across the
      // OCR'd words — a drug name can appear anywhere in a
      // multi-line prescription, mixed in with dosage/frequency text.
      for (var i = 0; i <= words.length - drugWords.length; i++) {
        final window = words.sublist(i, i + drugWords.length).join(' ');
        final score = _similarity(window, drug.name.toLowerCase());
        if (score > bestScore) bestScore = score;
      }

      // Also check single-word overlap against just the drug's first
      // word (e.g. "Amoxicillin" still matching even if a smudged
      // "500mg" right after it throws off the multi-word window).
      if (drugWords.length > 1) {
        for (final w in words) {
          final score = _similarity(w, drugWords.first);
          if (score > bestScore) bestScore = score;
        }
      }

      if (bestScore >= minScore) {
        matches.add(DrugMatch(drug: drug, score: bestScore));
      }
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.take(maxResults).toList();
  }

  double _similarity(String a, String b) {
    if (a == b) return 1.0;
    final maxLen = math.max(a.length, b.length);
    if (maxLen == 0) return 1.0;
    final distance = _levenshtein(a, b);
    return 1 - (distance / maxLen);
  }

  int _levenshtein(String a, String b) {
    final la = a.length;
    final lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;

    var previousRow = List<int>.generate(lb + 1, (j) => j);
    var currentRow = List<int>.filled(lb + 1, 0);

    for (var i = 0; i < la; i++) {
      currentRow[0] = i + 1;
      for (var j = 0; j < lb; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        currentRow[j + 1] = [
          currentRow[j] + 1, // insertion
          previousRow[j + 1] + 1, // deletion
          previousRow[j] + cost, // substitution
        ].reduce(math.min);
      }
      final temp = previousRow;
      previousRow = currentRow;
      currentRow = temp;
    }
    return previousRow[lb];
  }

  void dispose() {
    _recognizer.close();
  }
}