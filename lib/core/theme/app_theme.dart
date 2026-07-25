import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryNavy = Color(0xFF1A3A5C);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color inStockGreen = Color(0xFF16A34A);
  static const Color lowStockOrange = Color(0xFFEA580C);
  static const Color borderGrey = Color(0xFFE5E7EB);

  static ThemeData get theme => ThemeData(
    primaryColor: primaryNavy,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryNavy),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: primaryNavy,
      elevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: UnderlineInputBorder(),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryNavy,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryNavy,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: UnderlineInputBorder(),
    ),
  );

  static Color navBarSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
  }

  static Color navBarGlassColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
  }

  static const double navBarClearance = 50;
}
