import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../core/constants/app_routes.dart';

/// Wraps a staff-only screen. If the signed-in user isn't staff (or
/// isn't signed in), it redirects to the customer Home screen instead
/// of rendering the protected screen — this is what actually stops a
/// customer from reaching Inventory/Order Management/etc. by
/// navigating to the route directly, which the old code didn't check
/// at all.
class StaffOnly extends StatelessWidget {
  final Widget child;

  const StaffOnly({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isStaff) {
      return child;
    }

    // Not staff (or session dropped) — bounce back to Home rather than
    // showing any staff content, then schedule the actual navigation
    // for after this frame since we can't call Navigator during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
