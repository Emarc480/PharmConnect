import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../providers/drug_provider.dart';
import '../providers/order_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/refill_provider.dart';
import '../models/order.dart';

enum _Severity { critical, warning, info }

class _NotificationItem {
  final IconData icon;
  final _Severity severity;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.icon,
    required this.severity,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

/// In-app notification center — no push infrastructure required.
/// Instead of a separate Firestore-backed "notifications" collection,
/// this reads the same live provider data already streaming
/// elsewhere in the app (DrugProvider, RefillProvider,
/// PrescriptionProvider, OrderProvider) and turns it into a sorted,
/// actionable list. Simpler and can't drift out of sync with the
/// underlying data the way a separately-written notification doc
/// could.
class StaffNotificationsScreen extends StatelessWidget {
  const StaffNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final drugs = context.watch<DrugProvider>();
    final refills = context.watch<RefillProvider>();
    final prescriptions = context.watch<PrescriptionProvider>();
    final orders = context.watch<OrderProvider>();

    final items = <_NotificationItem>[];

    for (final drug in drugs.expiredDrugs) {
      items.add(_NotificationItem(
        icon: Icons.dangerous_outlined,
        severity: _Severity.critical,
        title: '${drug.name} has expired',
        subtitle: 'Expired ${drug.expiryLabel} · remove from sale',
        onTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
      ));
    }
    for (final drug in drugs.allDrugs.where((d) => d.stockQuantity <= 0)) {
      items.add(_NotificationItem(
        icon: Icons.block_rounded,
        severity: _Severity.critical,
        title: '${drug.name} is out of stock',
        subtitle: 'Restock needed as soon as possible',
        onTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
      ));
    }
    for (final drug in drugs.lowStockDrugs.where((d) => d.stockQuantity > 0)) {
      items.add(_NotificationItem(
        icon: Icons.warning_amber_rounded,
        severity: _Severity.warning,
        title: '${drug.name} is low on stock',
        subtitle: '${drug.stockQuantity} units left · reorder level ${drug.reorderLevel}',
        onTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
      ));
    }
    for (final drug in drugs.expiringSoonDrugs) {
      items.add(_NotificationItem(
        icon: Icons.event_busy_outlined,
        severity: _Severity.warning,
        title: '${drug.name} expires soon',
        subtitle: 'Expires ${drug.expiryLabel}',
        onTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
      ));
    }
    final newOrders = orders.orders.where((o) => o.status == OrderStatus.placed).length;
    if (newOrders > 0) {
      items.add(_NotificationItem(
        icon: Icons.receipt_long_outlined,
        severity: _Severity.info,
        title: '$newOrders new order${newOrders == 1 ? '' : 's'} to process',
        subtitle: 'Waiting to be prepared',
        onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
      ));
    }
    if (refills.pendingCount > 0) {
      items.add(_NotificationItem(
        icon: Icons.refresh,
        severity: _Severity.info,
        title: '${refills.pendingCount} pending refill request${refills.pendingCount == 1 ? '' : 's'}',
        subtitle: 'Awaiting review',
        onTap: () => Navigator.pushNamed(context, AppRoutes.refillManagement),
      ));
    }
    if (prescriptions.pendingCount > 0) {
      items.add(_NotificationItem(
        icon: Icons.description_outlined,
        severity: _Severity.info,
        title: '${prescriptions.pendingCount} prescription${prescriptions.pendingCount == 1 ? '' : 's'} to review',
        subtitle: 'Awaiting review',
        onTap: () => Navigator.pushNamed(context, AppRoutes.prescriptionManagement),
      ));
    }

    // Most urgent first.
    items.sort((a, b) => a.severity.index.compareTo(b.severity.index));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text("You're all caught up", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, AppTheme.navBarClearance),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _NotificationTile(item: items[i]),
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final _NotificationItem item;

  Color get _color {
    switch (item.severity) {
      case _Severity.critical:
        return Colors.red;
      case _Severity.warning:
        return AppTheme.lowStockOrange;
      case _Severity.info:
        return AppTheme.primaryNavy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.navBarSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderGrey),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(item.icon, size: 18, color: _color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
