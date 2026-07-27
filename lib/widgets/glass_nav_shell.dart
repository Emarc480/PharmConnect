import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Shared "floating glass pill" chrome for the bottom nav bars —
/// blurred, translucent background plus a soft tinted capsule that
/// slides behind whichever tab is active, matching Telegram's 2026
/// "Liquid Glass" bottom bar (translucent floating pill, frosted
/// blur, an animated highlight behind the selected tab rather than
/// just a recolored icon).
///
/// Both FloatingNavBar and StaffFloatingNavBar build their own Row of
/// items and hand it in as `child`; this widget owns the shape, blur,
/// color, shadow, and sliding indicator — pulling this out once means
/// the two nav bars can't drift out of sync the way they did with the
/// dark-mode colors.
class GlassNavShell extends StatelessWidget {
  const GlassNavShell({
    super.key,
    required this.child,
    required this.itemCount,
    required this.activeIndex,
  });

  final Widget child;

  /// How many evenly-spaced tabs [child]'s Row lays out — needed here
  /// so the indicator can compute each tab's slot width for itself
  /// rather than the nav bars tracking their own indicator geometry.
  final int itemCount;

  /// Index of the currently-selected tab; the indicator animates to
  /// this slot whenever it changes.
  final int activeIndex;

  static const double height = 68;
  static const double radius = 34;
  static const double _indicatorInset = 6;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

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
                    // Translucent, not opaque — this is what actually
                    // lets the BackdropFilter blur read as "glass"
                    // instead of a flat card that happens to sit atop
                    // a blur nobody can see.
                    color: AppTheme.navBarGlassColor(context),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final slotWidth = constraints.maxWidth / itemCount;
                      return Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            left: slotWidth * activeIndex + _indicatorInset,
                            top: 8,
                            bottom: 8,
                            width: slotWidth - (_indicatorInset * 2),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: isDark ? 0.24 : 0.13),
                                borderRadius: BorderRadius.circular(radius - 8),
                              ),
                            ),
                          ),
                          child,
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
