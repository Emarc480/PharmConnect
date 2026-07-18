import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.primaryNavy,
              child: Icon(Icons.person, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 24),
            _ProfileRow(label: 'Name', value: user?.name ?? '—'),
            _ProfileRow(label: 'Email', value: user?.email ?? '—'),
            _ProfileRow(label: 'Role', value: user?.role.label ?? '—'),
            const SizedBox(height: 24),
            const Divider(),
            _MenuTile(
              icon: Icons.receipt_long_outlined,
              label: 'My Orders',
              onTap: () => Navigator.pushNamed(context, AppRoutes.myOrders),
            ),
            _MenuTile(
              icon: Icons.refresh,
              label: 'Refill Request',
              onTap: () => Navigator.pushNamed(context, AppRoutes.refill),
            ),
            const Divider(),
            const SizedBox(height: 12),
            OutlinedButton(
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
              ),
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primaryNavy),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}