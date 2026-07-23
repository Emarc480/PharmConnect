import 'dart:ui';

import 'package:flutter/material.dart';

/// Shared visual building blocks for the two-column product/inventory
/// grid cards used on the customer Home/Store tabs and the staff
/// Inventory screen, so both sides stay visually in sync from one
/// place instead of drifting apart as separate copy-pasted styles.

/// Card-level constants — radius and shadow — pulled out so
/// [ProductGridCard] and the staff inventory card share exactly the
/// same shell.
class GridCardStyle {
  static const double radius = 20;
  static const double imageRadius = 20;

  /// Border-less "soft elevation" look: a faint hairline plus a wide,
  /// low-opacity shadow instead of a hard 1px grey border.
  static Border get hairline => Border.all(
        color: Colors.black.withValues(alpha: 0.045),
        width: 1,
      );

  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 22,
          offset: const Offset(0, 10),
          spreadRadius: -6,
        ),
      ];
}

/// Small frosted-glass circular icon button used for the wishlist
/// heart (customer side) and the edit pencil (staff side), floating
/// over the product photo.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(6.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 15, color: color ?? Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}

/// Floating pill badge shown top-left over the product photo — used
/// for the discount %, low-stock, and out-of-stock states, replacing
/// the old flush-left flag-shaped tag.
class GridCardBadge extends StatelessWidget {
  const GridCardBadge({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small tinted category chip shown under the product name — replaces
/// the older bare icon+label row with something that reads as a tag.
class CategoryPill extends StatelessWidget {
  const CategoryPill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}