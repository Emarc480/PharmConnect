import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';

/// Admin-only screen (see AdminOnly guard) for managing who has staff
/// access. Client apps can't delete other people's Firebase Auth
/// accounts without the Admin SDK, so "removing" a staff member here
/// means deactivating them (isActive: false) — StaffOnly then treats
/// them as a regular customer for screen access — rather than an
/// irreversible delete.
///
/// Reads the `users` collection directly with a StreamBuilder rather
/// than a dedicated provider, since this is the only screen that
/// needs the full user list.
class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selfUid = context.watch<AuthProvider>().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Staff Management', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').orderBy('name').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Could not load accounts.', style: TextStyle(color: Colors.grey.shade600)));
            }
            final docs = snapshot.data?.docs ?? [];
            final users = docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
            final staff = users.where((u) => u.role == UserRole.staff).toList();
            final customers = users.where((u) => u.role == UserRole.customer).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, AppTheme.navBarClearance),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNavy.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppTheme.primaryNavy),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Deactivating an account blocks staff-side access without deleting it. Promoting a customer gives them full staff access immediately.',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Pharmacy Staff (${staff.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (staff.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No staff accounts yet.', style: TextStyle(color: Colors.grey.shade500)),
                  )
                else
                  for (final user in staff) _UserCard(user: user, isSelf: user.uid == selfUid),
                const SizedBox(height: 24),
                Text('Customers (${customers.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (customers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No customer accounts yet.', style: TextStyle(color: Colors.grey.shade500)),
                  )
                else
                  for (final user in customers) _UserCard(user: user, isSelf: user.uid == selfUid),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.isSelf});

  final AppUser user;
  final bool isSelf;

  Future<void> _update(BuildContext context, Map<String, dynamic> patch) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(patch);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update this account. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = user.role == UserRole.staff;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navBarSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.1),
                child: Icon(isStaff ? Icons.storefront_outlined : Icons.person_outline, color: AppTheme.primaryNavy, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name.isEmpty ? '(no name)' : user.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Text('(you)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ],
                    ),
                    Text(user.email, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (!user.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                  child: const Text('Deactivated', style: TextStyle(color: Colors.red, fontSize: 10.5, fontWeight: FontWeight.w700)),
                )
              else if (user.isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.inStockGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                  child: const Text('Admin', style: TextStyle(color: AppTheme.inStockGreen, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _update(context, {'role': (isStaff ? UserRole.customer : UserRole.staff).name}),
                icon: Icon(isStaff ? Icons.person_remove_outlined : Icons.person_add_alt_outlined, size: 16),
                label: Text(isStaff ? 'Demote to customer' : 'Promote to staff'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryNavy,
                  side: const BorderSide(color: AppTheme.primaryNavy),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              if (isStaff)
                OutlinedButton.icon(
                  onPressed: isSelf ? null : () => _update(context, {'isAdmin': !user.isAdmin}),
                  icon: Icon(user.isAdmin ? Icons.shield_outlined : Icons.shield_moon_outlined, size: 16),
                  label: Text(user.isAdmin ? 'Remove admin' : 'Make admin'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.inStockGreen,
                    side: const BorderSide(color: AppTheme.inStockGreen),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (isStaff)
                OutlinedButton.icon(
                  onPressed: isSelf ? null : () => _update(context, {'isActive': !user.isActive}),
                  icon: Icon(user.isActive ? Icons.block_outlined : Icons.check_circle_outline, size: 16),
                  label: Text(user.isActive ? 'Deactivate' : 'Reactivate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: user.isActive ? Colors.red : AppTheme.inStockGreen,
                    side: BorderSide(color: user.isActive ? Colors.red : AppTheme.inStockGreen),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
