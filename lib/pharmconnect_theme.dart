import 'package:flutter/material.dart';

/// PharmConnect Unified Medical Design Theme (Dart 3.12.2+ & Flutter 3.44.3+)
/// Defines the brand palette, custom typography, and button templates.
class PharmConnectTheme {
  // Brand Color Palette
  static const Color primaryTeal = Color(0xFF0D9488); // Deep Teal (#0D9488)
  static const Color primaryDark = Color(0xFF0F172A); // Slate-900 (#0F172A)
  static const Color bgSurface = Color(0xFFF8FAFC); // Off-White/Slate-50
  static const Color cardBg = Color(0xFFFFFFFF); // Pristine White

  // Status Accents
  static const Color statusPending = Color(0xFFD97706); // Amber-600
  static const Color statusProcessing = Color(0xFF2563EB); // Blue-600
  static const Color statusShipped = Color(0xFF16A34A); // Green-600

  // Neutral Greys
  static const Color textMain = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color borderLight = Color(0xFFE2E8F0); // Slate-200

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        surface: bgSurface,
        onSurface: textMain,
      ),
      scaffoldBackgroundColor: bgSurface,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: primaryDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: primaryTeal),
      ),
      cardTheme: const CardThemeData(
        color: cardBg,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderLight, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
        margin: EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}
