import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/view_mode_provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _switchView(BuildContext context, ViewMode target) {
    context.read<ViewModeProvider>().switchTo(target);
    final destination = target == ViewMode.staff
        ? AppRoutes.dashboard
        : AppRoutes.home;
    Navigator.pushNamedAndRemoveUntil(context, destination, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = context.watch<ViewModeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Currently viewing: ${viewMode.isStaff ? "Staff" : "Customer"} side',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            // TODO, Remove once real roles arrive from login api
            ElevatedButton(
              onPressed: () => _switchView(
                context,
                viewMode.isStaff ? ViewMode.customer : ViewMode.staff,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
              ),
              child: Text(
                viewMode.isStaff
                    ? 'Switch to Customer View'
                    : 'Switch to Staff View',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
