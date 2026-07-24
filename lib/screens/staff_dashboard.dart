import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/drug_provider.dart';
import '../providers/refill_provider.dart';



/// The Dashboard tab inside StaffHomeShell — no Scaffold/AppBar/nav
/// bar of its own (the shell provides those), matching how the
/// customer-side DashboardTab is just tab content. `onNavigateToTab`
/// lets stat cards and quick actions here switch straight to another
/// tab in the shell (e.g. tapping "Low Stock" jumps to Inventory)
/// instead of pushing a whole new screen on top.
class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key, required this.onNavigateToTab});

  final ValueChanged<int> onNavigateToTab;

  String _formatUgx(int amount) {
    final s = amount.toString();
    final withCommas = s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'UGX $withCommas';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final orders = context.watch<OrderProvider>().orders;
    final drugs = context.watch<DrugProvider>();
    final refills = context.watch<RefillProvider>();

    final newOrders = orders.where((o) => o.status == OrderStatus.placed).length;
    final todaysSales = orders
        .where((o) => o.orderDate.day == DateTime.now().day && o.orderDate.month == DateTime.now().month)
        .fold(0.0, (sum, o) => sum + o.total)
        .round();
    final recentOrders = orders.take(3).toList();
    final firstName = (user?.name ?? '').trim().split(' ').firstOrEmpty;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, AppTheme.navBarClearance),
        children: [
          Text(
            'Hi, ${firstName.isEmpty ? 'there' : firstName} 👋',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Here's what's happening at the pharmacy today.",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Stats grid — 2x2, tappable, jumps to the relevant tab or
          // staff screen instead of just displaying a static number.
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.receipt_long_outlined,
                  label: 'New Orders',
                  value: '$newOrders',
                  color: AppTheme.primaryNavy,
                  onTap: () => onNavigateToTab(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StatCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Low Stock',
                  value: '${drugs.lowStockCount}',
                  color: AppTheme.lowStockOrange,
                  onTap: () => onNavigateToTab(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.payments_outlined,
                  label: "Today's Sales",
                  value: _formatUgx(todaysSales),
                  color: AppTheme.inStockGreen,
                  onTap: () => onNavigateToTab(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StatCard(
                  icon: Icons.refresh,
                  label: 'Pending Refills',
                  value: '${refills.pendingCount}',
                  color: AppTheme.primaryNavy,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.refillManagement),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Recent activity — a quick pulse on what's coming in
          // without leaving the dashboard.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Orders', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => onNavigateToTab(2), child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 4),
          if (recentOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No orders yet', style: TextStyle(color: Colors.grey.shade500)),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < recentOrders.length; i++)
                    _RecentOrderRow(
                      order: recentOrders[i],
                      isLast: i == recentOrders.length - 1,
                      onTap: () => onNavigateToTab(2),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Primary CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => onNavigateToTab(2),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('View Orders', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.promoBannerManagement),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryNavy,
                side: BorderSide(color: AppTheme.borderGrey),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Manage Promo Banners', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrEmpty on List<String> {
  String get firstOrEmpty => isNotEmpty && first.isNotEmpty ? first : '';
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGrey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderRow extends StatelessWidget {
  const _RecentOrderRow({required this.order, required this.isLast, required this.onTap});

  final Order order;
  final bool isLast;
  final VoidCallback onTap;

  Color _statusColor() {
    switch (order.status) {
      case OrderStatus.placed:
        return AppTheme.lowStockOrange;
      case OrderStatus.processing:
        return AppTheme.primaryNavy;
      case OrderStatus.shipped:
        return AppTheme.primaryNavy;
      case OrderStatus.delivered:
        return AppTheme.inStockGreen;
    }
  }

  String _formatUgx(int amount) {
    final s = amount.toString();
    final withCommas = s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return 'UGX $withCommas';
  }

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase();
    final itemCount = order.items.fold(0, (sum, item) => sum + item.quantity);

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: _statusColor().withValues(alpha: 0.1),
            child: Icon(Icons.receipt_long_outlined, color: _statusColor(), size: 18),
          ),
          title: Text('Order #$shortId', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('$itemCount item${itemCount == 1 ? '' : 's'} · ${order.status.label}'),
          trailing: Text(
            _formatUgx(order.total.round()),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 72, color: AppTheme.borderGrey),
      ],
    );
  }
}