import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/refill_request.dart';
import '../providers/refill_provider.dart';
import '../core/theme/app_theme.dart';

class RefillRequestScreen extends StatefulWidget {
  const RefillRequestScreen({super.key});

  @override
  State<RefillRequestScreen> createState() => _RefillRequestScreenState();
}

class _RefillRequestScreenState extends State<RefillRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _drugController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _drugController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<RefillProvider>().submitRequest(
          drugName: _drugController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
    _drugController.clear();
    _notesController.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refill request submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<RefillProvider>().requests;

    return Scaffold(
      appBar: AppBar(title: const Text('Refill Requests')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('New Request', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _drugController,
                    decoration: const InputDecoration(labelText: 'Drug name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Drug name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes (optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Submit Request'),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),
            const Text('Your Requests', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            if (requests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No refill requests yet')),
              )
            else
              for (final request in requests) _RefillRequestTile(request: request),
          ],
        ),
      ),
    );
  }
}

class _RefillRequestTile extends StatelessWidget {
  final RefillRequest request;

  const _RefillRequestTile({required this.request});

  Color _statusColor() {
    switch (request.status) {
      case RefillStatus.pending:
        return AppTheme.lowStockOrange;
      case RefillStatus.approved:
        return AppTheme.primaryNavy;
      case RefillStatus.ready:
        return AppTheme.inStockGreen;
      case RefillStatus.declined:
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.drugName, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (request.notes != null) ...[
                  const SizedBox(height: 2),
                  Text(request.notes!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
              style: TextStyle(color: _statusColor(), fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
