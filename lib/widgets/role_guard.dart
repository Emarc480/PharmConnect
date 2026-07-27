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

    // A deactivated staff account (see Staff Management) is treated
    // the same as "not staff" for the purposes of reaching any
    // staff-only screen, without needing to force a sign-out.
    if (auth.isStaff && (auth.currentUser?.isActive ?? true)) {
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

/// Wraps the Staff Management screen. Requires both staff status AND
/// the `isAdmin` flag — a regular pharmacist can't promote/deactivate
/// coworkers, only an admin can. Non-admin staff bounce to the Staff
/// Dashboard (they're still staff, just not authorized for this
/// screen); anyone else bounces to Home, same as [StaffOnly].
class AdminOnly extends StatelessWidget {
  final Widget child;

  const AdminOnly({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isActiveStaff = auth.isStaff && (user?.isActive ?? true);

    if (isActiveStaff && user!.isAdmin) {
      return child;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      Navigator.of(context).pushReplacementNamed(
        isActiveStaff ? AppRoutes.staffDashboard : AppRoutes.home,
      );
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
