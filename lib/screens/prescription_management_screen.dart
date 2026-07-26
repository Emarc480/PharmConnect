import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/prescription_request.dart';
import '../providers/prescription_provider.dart';

/// Staff "Prescriptions" inbox — review each customer submission
/// (photo and/or typed order), then mark it reviewed / fulfilled /
/// rejected. Mirrors the status-pill styling used on the customer's
/// own submission list.
class PrescriptionManagementScreen extends StatefulWidget {
  const PrescriptionManagementScreen({super.key});

  @override
  State<PrescriptionManagementScreen> createState() => _PrescriptionManagementScreenState();
}

class _PrescriptionManagementScreenState extends State<PrescriptionManagementScreen> {
  PrescriptionStatus? _filter; // null == All

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();
    final requests = _filter == null
        ? provider.requests
        : provider.requests.where((r) => r.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Prescriptions')),
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      children: [
                        _FilterChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                        const SizedBox(width: 8),
                        for (final status in PrescriptionStatus.values) ...[
                          _FilterChip(
                            label: status.label,
                            selected: _filter == status,
                            onTap: () => setState(() => _filter = status),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: requests.isEmpty
                        ? Center(
                            child: Text('No submissions here', style: TextStyle(color: Colors.grey.shade500)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                            itemCount: requests.length,
                            itemBuilder: (context, i) => _PrescriptionCard(request: requests[i]),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryNavy,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final PrescriptionRequest request;
  const _PrescriptionCard({required this.request});

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

  String _formattedDate() {
    final d = request.submittedAt;
    return '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _PrescriptionDetailSheet(request: request),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderGrey),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade100,
              child: Icon(
                request.hasImage ? Icons.image_outlined : Icons.edit_note,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.requesterName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    request.typedOrder ?? 'Photo prescription',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(_formattedDate(), style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
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
      ),
    );
  }
}

class _PrescriptionDetailSheet extends StatefulWidget {
  final PrescriptionRequest request;
  const _PrescriptionDetailSheet({required this.request});

  @override
  State<_PrescriptionDetailSheet> createState() => _PrescriptionDetailSheetState();
}

class _PrescriptionDetailSheetState extends State<_PrescriptionDetailSheet> {
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(PrescriptionStatus status) async {
    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    try {
      await context.read<PrescriptionProvider>().updateStatus(
            widget.request.id,
            status,
            pharmacistNote: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          );
      navigator.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(request.requesterName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text(request.status.label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 16),
            if (request.hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  base64Decode(request.imageBase64!),
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            if (request.typedOrder != null) ...[
              const SizedBox(height: 12),
              const Text('Typed order', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(request.typedOrder!),
            ],
            if (request.notes != null) ...[
              const SizedBox(height: 12),
              const Text('Customer notes', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(request.notes!),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Note to attach with this update (optional)',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => _updateStatus(PrescriptionStatus.rejected),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => _updateStatus(PrescriptionStatus.reviewed),
                    child: const Text('Reviewed'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : () => _updateStatus(PrescriptionStatus.fulfilled),
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.inStockGreen),
                    child: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Fulfilled'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}