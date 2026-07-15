import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/refill_request.dart';
import '../providers/refill_provider.dart';
import '../core/theme/app_theme.dart';

class RefillManagementScreen extends StatelessWidget {
  const RefillManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<RefillProvider>().requests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refill Management', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: requests.isEmpty
            ? const Center(child: Text('No refill requests'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, i) => _RefillManagementRow(request: requests[i]),
              ),
      ),
    );
  }
}

class _RefillManagementRow extends StatelessWidget {
  final RefillRequest request;

  const _RefillManagementRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RefillProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.drugName, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (request.notes != null) ...[
                  const SizedBox(height: 2),
                  Text(request.notes!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
                const SizedBox(height: 4),
                Text(
                  request.status.label,
                  style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          ),
          if (request.status == RefillStatus.pending) ...[
            TextButton(
              onPressed: () => provider.updateStatus(request.id, RefillStatus.declined),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Decline'),
            ),
            TextButton(
              onPressed: () => provider.updateStatus(request.id, RefillStatus.approved),
              child: const Text('Approve'),
            ),
          ] else if (request.status == RefillStatus.approved)
            TextButton(
              onPressed: () => provider.updateStatus(request.id, RefillStatus.ready),
              child: const Text('Mark Ready'),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                request.status == RefillStatus.ready ? 'Ready' : 'Closed',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
