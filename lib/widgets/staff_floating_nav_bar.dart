import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/drug_provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';

/// Floating pill-shaped bottom navigation bar for the staff shell
/// (Dashboard / Inventory / Orders / Profile) — visually matches
/// `FloatingNavBar` on the customer side, but swaps the cart badge for
/// two operational ones staff actually care about: how many items are
/// low on stock, and how many orders are still open.
class StaffFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const StaffFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Inventory'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final lowStockCount = context.watch<DrugProvider>().lowStockCount;
    final openOrdersCount =
        context.watch<OrderProvider>().orders.where((o) => o.status != OrderStatus.delivered).length;

    // Index 1 = Inventory, index 2 = Orders — matches _items above.
    final badgeCounts = {1: lowStockCount, 2: openOrdersCount};
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inactiveColor = theme.colorScheme.onSurfaceVariant;
    final activeColor = theme.colorScheme.primary;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppTheme.navBarSurface(context),
            borderRadius: BorderRadius.circular(34),
            border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.08)) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isActive = i == currentIndex;
              final badgeCount = badgeCounts[i] ?? 0;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(34),
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: isActive ? activeColor : inactiveColor,
                            size: 24,
                          ),
                          if (badgeCount > 0)
                            Positioned(
                              right: -8,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: i == 1 ? AppTheme.lowStockOrange : Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(minWidth: 16),
                                child: Text(
                                  '$badgeCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? activeColor : inactiveColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}