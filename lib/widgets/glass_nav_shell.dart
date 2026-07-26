import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Shared "floating glass pill" chrome for the bottom nav bars —
/// blurred, translucent background (Telegram / Google Photos style)
/// instead of a flat opaque one.
///
/// Both FloatingNavBar and StaffFloatingNavBar build their own Row of
/// items and hand it in as `child`; this widget owns the shape, blur,
/// color, shadow, and — importantly — makes sure nothing scrolling
/// underneath (Scaffold(extendBody: true)) can be tapped *through*
/// the pill. Pulling this out once means the two nav bars can't drift
/// out of sync the way they did with the dark-mode colors.
class GlassNavShell extends StatelessWidget {
  const GlassNavShell({super.key, required this.child});

  final Widget child;

  static const double height = 68;
  static const double radius = 34;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        // Without this, taps in the gaps between item InkWells (and
        // the transparent corners just outside the rounded pill
        // shape) fall straight through to whatever is scrolling
        // underneath. HitTestBehavior.opaque claims the whole
        // rectangle regardless of what's actually painted there,
        // while the item InkWells below still win their own taps
        // normally.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Container(
            // Shadow lives on this outer, unclipped layer — putting it
            // on the same box as the ClipRRect below would cut it off,
            // since ClipRRect clips everything to its own bounds,
            // shadow included.
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: AppTheme.navBarGlassColor(context),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}