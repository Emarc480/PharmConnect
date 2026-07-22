import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/drug_provider.dart';
import '../providers/order_provider.dart';
import '../providers/refill_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isStaff = user?.role == UserRole.staff;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        title: const Text('Account'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            AppTheme.navBarClearance,
          ),
          children: [
            _ProfileHeader(user: user, isStaff: isStaff),
            const SizedBox(height: 20),
            if (isStaff) ...[
              const _SectionLabel('Overview'),
              const SizedBox(height: 10),
              const _StaffOverviewStats(),
              const SizedBox(height: 20),
            ],
            _SectionLabel(isStaff ? 'Management' : 'My Activity'),
            const SizedBox(height: 10),
            _MenuCard(
              children: isStaff
                  ? [
                      _MenuTile(
                        icon: Icons.inventory_2_outlined,
                        label: 'Inventory',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.inventory),
                      ),
                      _MenuTile(
                        icon: Icons.receipt_long_outlined,
                        label: 'Manage Orders',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.orders),
                      ),
                      _MenuTile(
                        icon: Icons.refresh,
                        label: 'Refill Requests',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.refillManagement,
                        ),
                      ),
                      _MenuTile(
                        icon: Icons.description_outlined,
                        label: 'Prescriptions',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.prescriptionManagement,
                        ),
                      ),
                      _MenuTile(
                        icon: Icons.chat_bubble_outline,
                        label: 'Customer Messages',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.staffMessages,
                        ),
                      ),
                      _MenuTile(
                        icon: Icons.settings_outlined,
                        label: 'App Settings',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.appSettings),
                        isLast: true,
                      ),
                    ]
                  : [
                      _MenuTile(
                        icon: Icons.receipt_long_outlined,
                        label: 'My Orders',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.myOrders),
                      ),
                      _MenuTile(
                        icon: Icons.refresh,
                        label: 'Refill Request',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.refill),
                      ),
                      _MenuTile(
                        icon: Icons.description_outlined,
                        label: 'Prescriptions',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.prescription,
                        ),
                      ),
                      _MenuTile(
                        icon: Icons.notifications_outlined,
                        label: 'Reminders',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.reminders),
                      ),
                      _MenuTile(
                        icon: Icons.support_agent_outlined,
                        label: 'Ask a Pharmacist',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.askPharmacist,
                        ),
                      ),
                      _MenuTile(
                        icon: Icons.settings_outlined,
                        label: 'App Settings',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.appSettings),
                        isLast: true,
                      ),
                    ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                // No manual navigation needed: AuthGate at the app root
                // watches AuthProvider and swaps to LoginScreen the
                // moment the session is cleared. We still pop back to
                // the root first so no stale pushed screens are left
                // sitting on top of it.
                Navigator.of(context).popUntil((route) => route.isFirst);
                context.read<AuthProvider>().signOut();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Log Out'),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'PharmConnect · v1.1.7',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft gradient card up top: avatar, name, email, and a role badge
/// that visually distinguishes staff accounts from customer accounts
/// (previously both looked identical).
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.isStaff});

  final AppUser? user;
  final bool isStaff;

  String get _initials {
    final name = user?.name.trim() ?? '';
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isStaff
              ? [AppTheme.primaryNavy, const Color(0xFF2E5A8C)]
              : [
                  AppTheme.primaryNavy.withValues(alpha: 0.9),
                  AppTheme.inStockGreen.withValues(alpha: 0.85),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              _initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user?.name ?? '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '—',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isStaff ? Icons.storefront_outlined : Icons.person_outline,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  user?.role.label ?? '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Live at-a-glance numbers pulled from the same providers the staff
/// screens already use — tapping a card jumps straight into that
/// screen instead of making staff dig through the menu below.
class _StaffOverviewStats extends StatelessWidget {
  const _StaffOverviewStats();

  @override
  Widget build(BuildContext context) {
    final lowStockCount = context
        .watch<DrugProvider>()
        .allDrugs
        .where((d) => d.isLowStock)
        .length;
    final pendingOrders = context
        .watch<OrderProvider>()
        .orders
        .where((o) => o.status != OrderStatus.delivered)
        .length;
    final pendingRefills = context.watch<RefillProvider>().pendingCount;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: lowStockCount,
            label: 'Low Stock',
            icon: Icons.warning_amber_rounded,
            color: AppTheme.lowStockOrange,
            onTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: pendingOrders,
            label: 'Open Orders',
            icon: Icons.local_shipping_outlined,
            color: AppTheme.primaryNavy,
            onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: pendingRefills,
            label: 'Refills',
            icon: Icons.refresh,
            color: AppTheme.inStockGreen,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.refillManagement),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGrey),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppTheme.primaryNavy),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
        if (!isLast) Divider(height: 1, indent: 56, color: AppTheme.borderGrey),
      ],
    );
  }
}
