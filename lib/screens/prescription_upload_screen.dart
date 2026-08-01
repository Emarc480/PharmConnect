import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/constants/ai_config.dart';
import '../core/theme/app_theme.dart';
import '../models/prescription_request.dart';
import '../providers/auth_provider.dart';
import '../providers/drug_provider.dart';
import '../providers/prescription_provider.dart';
import '../services/prescription_vision_service.dart';

/// "Upload prescription" / "Type your order" screen. Customers either
/// snap or pick a photo of a paper prescription, type out what they
/// need in plain text, or both — then track review status below.
class PrescriptionUploadScreen extends StatefulWidget {
  const PrescriptionUploadScreen({super.key});

  @override
  State<PrescriptionUploadScreen> createState() => _PrescriptionUploadScreenState();
}

class _PrescriptionUploadScreenState extends State<PrescriptionUploadScreen> {
  final _orderController = TextEditingController();
  final _notesController = TextEditingController();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  File? _pickedImage;
  bool _isScanning = false;

  @override
  void dispose() {
    _orderController.dispose();
    _notesController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        // Handwriting needs finer detail than a typical photo to read
        // reliably, so this is higher than other image pickers in the
        // app — still comfortably under Firestore's 1MB inline-image
        // cap once base64-encoded.
        maxWidth: 1800,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _pickedImage = File(picked.path));
        _scanPrescription();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera/gallery.')),
      );
    }
  }

  /// Reads the picked prescription photo. Doctors' handwriting is
  /// exactly the case plain character-recognition OCR struggles with,
  /// so this prefers [PrescriptionVisionService] — a vision model that
  /// reads the page the way a pharmacist would, cross-referencing
  /// drug-name spelling, dosage conventions, and (when available) this
  /// pharmacy's own catalog, while honestly flagging anything it isn't
  /// sure about. Plain on-device ML Kit OCR is only used as a fallback
  /// when that's unavailable (no API key configured) or fails (e.g. no
  /// internet). Either way, results are always shown for the patient
  /// to review and edit — never auto-submitted as-is.
  Future<void> _scanPrescription() async {
    final image = _pickedImage;
    if (image == null) return;

    setState(() => _isScanning = true);
    try {
      if (AiConfig.isConfigured) {
        try {
          final catalogNames = mounted
              ? context.read<DrugProvider>().allDrugs.map((d) => d.name).toList()
              : const <String>[];
          final scan = await PrescriptionVisionService.analyze(
            imageFile: image,
            catalogDrugNames: catalogNames,
          );
          if (!mounted) return;
          if (scan.items.isEmpty && scan.transcript.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No text could be read from that photo — try a clearer, well-lit shot, or type the order manually.'),
              ),
            );
            return;
          }
          await _showSmartScanReviewDialog(scan);
          return;
        } catch (_) {
          // Smart scan failed (offline, quota, blocked response, etc.)
          // — fall through to plain on-device OCR below rather than
          // leaving the patient with nothing.
        }
      }

      final inputImage = InputImage.fromFile(image);
      final result = await _textRecognizer.processImage(inputImage);
      final recognizedText = result.text.trim();
      if (!mounted) return;

      if (recognizedText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No text could be read from that photo — try a clearer, well-lit shot, or type the order manually.'),
          ),
        );
        return;
      }
      await _showPlainOcrReviewDialog(recognizedText);
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Color _confidenceColor(ScanConfidence c) {
    switch (c) {
      case ScanConfidence.high:
        return AppTheme.inStockGreen;
      case ScanConfidence.medium:
        return AppTheme.lowStockOrange;
      case ScanConfidence.low:
        return Colors.red;
    }
  }

  /// Structured review for the smart handwriting-aware scan: one card
  /// per medicine line with an editable field, a confidence badge, and
  /// (when the model was genuinely torn between readings) tappable
  /// alternate spellings — so fixing a misread doctor scrawl is a tap
  /// instead of a guessing-game retype.
  Future<void> _showSmartScanReviewDialog(PrescriptionScanResult scan) async {
    final lineControllers = <TextEditingController>[
      for (final item in scan.items) TextEditingController(text: item.toOrderLine()),
    ];
    // Whole-transcript fallback box, used when the model couldn't
    // confidently split things into line items at all.
    final fallbackController = TextEditingController(text: scan.transcript);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Review scanned prescription'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doctors\' handwriting is hard even for humans — check each line against the photo and fix anything that\'s wrong.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    if (scan.unclearNotes != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                scan.unclearNotes!,
                                style: const TextStyle(color: Colors.red, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (scan.items.isEmpty)
                      TextField(
                        controller: fallbackController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      )
                    else
                      for (var i = 0; i < scan.items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _confidenceColor(scan.items[i].confidence).withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      scan.items[i].confidence.label,
                                      style: TextStyle(
                                        color: _confidenceColor(scan.items[i].confidence),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  if (scan.items[i].catalogMatch) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'In stock catalog',
                                        style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w600, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: lineControllers[i],
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                ),
                              ),
                              if (scan.items[i].alternates.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Could also be:',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final alt in scan.items[i].alternates)
                                      ActionChip(
                                        label: Text(alt, style: const TextStyle(fontSize: 12)),
                                        backgroundColor: Colors.white,
                                        side: BorderSide(color: Colors.grey.shade300),
                                        onPressed: () {
                                          final rest = scan.items[i].dosage;
                                          setDialogState(() {
                                            lineControllers[i].text =
                                                rest != null ? '$alt $rest' : alt;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Discard'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
                child: const Text('Use this'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && mounted) {
      final lines = scan.items.isEmpty
          ? fallbackController.text.trim()
          : lineControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).join('\n');
      if (lines.isNotEmpty) {
        setState(() {
          _orderController.text = _orderController.text.trim().isEmpty
              ? lines
              : '${_orderController.text.trim()}\n$lines';
        });
      }
    }
    for (final c in lineControllers) {
      c.dispose();
    }
    fallbackController.dispose();
  }

  /// Fallback review dialog used only when the smart scan couldn't run
  /// (offline, no API key configured, request failed) and plain
  /// on-device OCR was used instead.
  Future<void> _showPlainOcrReviewDialog(String recognizedText) async {
    final editController = TextEditingController(text: recognizedText);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review scanned text'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Basic scan mode (smart handwriting reading is unavailable right now) — check this closely against the photo and fix anything that\'s wrong.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: editController,
                maxLines: 6,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
            child: const Text('Use this text'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final edited = editController.text.trim();
      setState(() {
        _orderController.text = _orderController.text.trim().isEmpty
            ? edited
            : '${_orderController.text.trim()}\n$edited';
      });
    }
    editController.dispose();
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppTheme.primaryNavy),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryNavy),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final hasImage = _pickedImage != null;
    final hasOrder = _orderController.text.trim().isNotEmpty;
    if (!hasImage && !hasOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attach a photo or type your order first')),
      );
      return;
    }
    final user = context.read<AuthProvider>().currentUser;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<PrescriptionProvider>().submit(
            imageFile: _pickedImage,
            typedOrder: _orderController.text,
            notes: _notesController.text,
            requesterName: user?.name ?? 'Customer',
          );
      setState(() {
        _pickedImage = null;
        _orderController.clear();
        _notesController.clear();
      });
      if (mounted) FocusScope.of(context).unfocus();
      messenger.showSnackBar(
        const SnackBar(content: Text('Prescription submitted — a pharmacist will review it shortly')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not submit: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prescriptionProvider = context.watch<PrescriptionProvider>();
    final myRequests = prescriptionProvider.myRequests;

    return Scaffold(
      appBar: AppBar(title: const Text('Prescription')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Upload prescription', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            InkWell(
              onTap: _showSourceSheet,
              borderRadius: BorderRadius.circular(16),
              child: DottedBox(
                child: _pickedImage == null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.inStockGreen, width: 1.5),
                              ),
                              child: const Icon(Icons.file_upload_outlined, color: AppTheme.inStockGreen),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Upload a photo of\nvalid Prescription or Product',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              _pickedImage!,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (_isScanning)
                            Container(
                              width: double.infinity,
                              height: 220,
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(color: Colors.white),
                                    SizedBox(height: 10),
                                    Text('Reading prescription…', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              radius: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                onPressed: _isScanning ? null : () => setState(() => _pickedImage = null),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_pickedImage != null && !_isScanning) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _scanPrescription,
                  icon: const Icon(Icons.document_scanner_outlined, size: 18),
                  label: const Text('Re-scan text from photo'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryNavy),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Type your order', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'Type here the medicine name or the product name that you want to order',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _orderController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Amoxicillin 500mg, x2 boxes',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Notes for the pharmacist (optional)',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: prescriptionProvider.isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: prescriptionProvider.isSubmitting
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit'),
            ),
            const Divider(height: 40),
            const Text('Your Submissions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            if (myRequests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No prescriptions submitted yet')),
              )
            else
              for (final request in myRequests) _PrescriptionTile(request: request),
          ],
        ),
      ),
    );
  }
}

class DottedBox extends StatelessWidget {
  final Widget child;
  const DottedBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.inStockGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.inStockGreen.withValues(alpha: 0.5), width: 1.4),
      ),
      child: child,
    );
  }
}

class _PrescriptionTile extends StatelessWidget {
  final PrescriptionRequest request;
  const _PrescriptionTile({required this.request});

  Color _statusColor() {
    switch (request.status) {
      case PrescriptionStatus.pending:
        return AppTheme.lowStockOrange;
      case PrescriptionStatus.reviewed:
        return AppTheme.primaryNavy;
      case PrescriptionStatus.fulfilled:
        return AppTheme.inStockGreen;
      case PrescriptionStatus.rejected:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            request.hasImage ? Icons.image_outlined : Icons.edit_note,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.typedOrder ?? 'Photo prescription',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (request.pharmacistNote != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Pharmacist: ${request.pharmacistNote}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor().withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              request.status.label,
              style: TextStyle(color: _statusColor(), fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}