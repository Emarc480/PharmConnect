import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_mode_provider.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Account Deletion'),
        content: const Text(
          'This submits a request to permanently delete your account. '
          'Your data is not deleted immediately — our team reviews the '
          'request and follows up by email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Request Deletion'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<AuthProvider>().requestAccountDeletion();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Deletion request submitted. We'll be in touch by email.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeModeProvider>();
    final auth = context.watch<AuthProvider>();
    final deletionRequested = auth.currentUser?.deletionRequested ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const _SectionLabel('App Mode'),
            const SizedBox(height: 10),
            _ThemeModeCard(
              currentMode: themeProvider.themeMode,
              onChanged: themeProvider.setThemeMode,
            ),
            const SizedBox(height: 28),
            const _SectionLabel('Account'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.navBarSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: ListTile(
                leading: Icon(
                  deletionRequested ? Icons.hourglass_top : Icons.delete_outline,
                  color: Colors.red,
                ),
                title: Text(
                  deletionRequested ? 'Deletion Requested' : 'Request Account Deletion',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
                ),
                subtitle: deletionRequested ? const Text('Pending review by our team') : null,
                onTap: deletionRequested ? null : () => _confirmDeleteAccount(context),
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

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({required this.currentMode, required this.onChanged});

  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  String _labelFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'Automatic';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.navBarSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        children: ThemeMode.values.map((mode) {
          final isLast = mode == ThemeMode.values.last;
          return Column(
            children: [
              RadioListTile<ThemeMode>(
                value: mode,
                groupValue: currentMode,
                onChanged: (m) => m != null ? onChanged(m) : null,
                title: Text(_labelFor(mode)),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              if (!isLast) Divider(height: 1, indent: 16, color: AppTheme.borderGrey),
            ],
          );
        }).toList(),
      ),
    );
  }
}