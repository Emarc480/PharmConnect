import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/inventory_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/drug_provider.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/view_mode_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        // Marcus' providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DrugProvider()),
        ChangeNotifierProvider(create: (_) => ViewModeProvider()),
      ],
      child: const PharmConnectApp(),
    ),
  );
}

class PharmConnectApp extends StatelessWidget {
  const PharmConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PharmConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}