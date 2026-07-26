import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/prescription_request.dart';
import '../models/drug.dart';
import '../providers/auth_provider.dart';
import '../providers/drug_provider.dart';
import '../providers/prescription_provider.dart';
import '../services/prescription_ocr_service.dart';

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
  File? _pickedImage;

  final _ocrService = PrescriptionOcrService();
  bool _isScanning = false;
  String? _ocrRawText;
  List<DrugMatch> _suggestions = [];  

  @override
  void dispose() {
    _orderController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 65,
      );
      if (picked != null) {
        setState(() => _pickedImage = File(picked.path));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera/gallery.')),
      );
    }
  }

  //reading the photo offine
  Future<void> _runOcr() async {
    final image = _pickedImage;
    if (image == null) return;

    setState(() => _isScanning = true);
    try {
      final text = await _ocrService.extractText(image);
      if (!mounted) return;
      final catalog = context.read<DrugProvider>().allDrugs;
      final matches = _ocrService.matchDrugs(text, catalog);
      setState(() {
        _ocrRawText = text.trim();
        _suggestions = matches;
      });
    } catch (_) {
      // Silent failure is fine here — OCR is a convenience, not a
      // requirement. Typing the order manually still works.
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  //for the suggestions
  void _applySuggestion(Drug drug) {
    final current = _orderController.text.trim();
    _orderController.text = current.isEmpty ? drug.name : '$current, ${drug.name}';
    _orderController.selection = TextSelection.collapsed(offset: _orderController.text.length);
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
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              radius: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                onPressed: () => setState(() => _pickedImage = null),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            //OCR feedback
            if (_pickedImage != null) ...[
              const SizedBox(height: 12),
              if (_isScanning)
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Reading prescription…',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                )
              else if (_suggestions.isNotEmpty) ...[
                Text(
                  'Possible matches — tap to add to your order:',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions.map((match) {
                    return ActionChip(
                      avatar: const Icon(Icons.auto_awesome, size: 16),
                      label: Text(match.drug.name),
                      onPressed: () => _applySuggestion(match.drug),
                    );
                  }).toList(),
                ),
              ] else if (_ocrRawText != null && _ocrRawText!.isEmpty)
                Text(
                  "Couldn't make out any text in that photo — no problem, just type the order below.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                )
              else if (_ocrRawText != null)
                Text(
                  "Couldn't confidently match anything in our catalog — type the order below, or double-check the photo is clear.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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