import 'package:flutter/material.dart';

/// The 18 drug categories used across the whole app — Inventory's
/// category filter, the customer Store tab, and the fallback icon
/// shown on any drug that doesn't have a real photo yet. Fixed (not
/// derived from whatever drugs happen to exist) so every category
/// always shows, even before any drug has been added to it.
const List<String> kDrugCategories = [
  'Pain & Fever',
  'Antibiotics',
  'Antimalarials',
  'Dewormers',
  'HIV (ARVs)',
  'TB Medicines',
  'Cough & Cold',
  'Allergy',
  'Stomach',
  'Diabetes',
  'Blood Pressure',
  'Heart',
  "Women's Health",
  "Children's Medicines",
  'Skin Medicines',
  'Eye & Ear',
  'Vitamins & Supplements',
  'Emergency Medicines',
];

/// One icon per category — used as the fallback thumbnail wherever a
/// drug has no staff-uploaded photo, so the catalog reads as
/// intentionally designed rather than a wall of identical pill icons.
IconData categoryIcon(String category) {
  switch (category) {
    case 'Pain & Fever':
      return Icons.local_fire_department_outlined;
    case 'Antibiotics':
      return Icons.coronavirus_outlined;
    case 'Antimalarials':
      return Icons.pest_control_outlined;
    case 'Dewormers':
      return Icons.bug_report_outlined;
    case 'HIV (ARVs)':
      return Icons.favorite_border;
    case 'TB Medicines':
      return Icons.air_outlined;
    case 'Cough & Cold':
      return Icons.sick_outlined;
    case 'Allergy':
      return Icons.grass_outlined;
    case 'Stomach':
      return Icons.restaurant_outlined;
    case 'Diabetes':
      return Icons.water_drop_outlined;
    case 'Blood Pressure':
      return Icons.monitor_heart_outlined;
    case 'Heart':
      return Icons.favorite;
    case "Women's Health":
      return Icons.pregnant_woman_outlined;
    case "Children's Medicines":
      return Icons.child_care_outlined;
    case 'Skin Medicines':
      return Icons.spa_outlined;
    case 'Eye & Ear':
      return Icons.visibility_outlined;
    case 'Vitamins & Supplements':
      return Icons.eco_outlined;
    case 'Emergency Medicines':
      return Icons.emergency_outlined;
    default:
      return Icons.medication_outlined;
  }
}

/// Matching accent color per category, used for the icon and its
/// tinted background wherever categoryIcon() is used.
Color categoryColor(String category) {
  switch (category) {
    case 'Pain & Fever':
      return const Color(0xFFDC2626); // red
    case 'Antibiotics':
      return const Color(0xFF2563EB); // blue
    case 'Antimalarials':
      return const Color(0xFF16A34A); // green
    case 'Dewormers':
      return const Color(0xFF92400E); // brown
    case 'HIV (ARVs)':
      return const Color(0xFF7C3AED); // purple
    case 'TB Medicines':
      return const Color(0xFF4338CA); // indigo
    case 'Cough & Cold':
      return const Color(0xFF0284C7); // light blue
    case 'Allergy':
      return const Color(0xFFD97706); // amber
    case 'Stomach':
      return const Color(0xFFEA580C); // orange
    case 'Diabetes':
      return const Color(0xFFDB2777); // pink
    case 'Blood Pressure':
      return const Color(0xFFB91C1C); // strong red
    case 'Heart':
      return const Color(0xFFE11D48); // rose
    case "Women's Health":
      return const Color(0xFFDB2777); // pink
    case "Children's Medicines":
      return const Color(0xFF0891B2); // cyan
    case 'Skin Medicines':
      return const Color(0xFF0D9488); // teal
    case 'Eye & Ear':
      return const Color(0xFF475569); // blue-grey
    case 'Vitamins & Supplements':
      return const Color(0xFF65A30D); // light green
    case 'Emergency Medicines':
      return const Color(0xFFB91C1C); // urgent red
    default:
      return const Color(0xFF6B7280); // grey
  }
}