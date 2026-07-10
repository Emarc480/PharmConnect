import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/inventory_provider.dart';
import 'routes/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/drug_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => InventoryProvider(),
        ),
      ],
      child: const PharmConnect(),
    ),
  );
}

class PharmConnect extends StatelessWidget {
  const PharmConnect({super.key});
        //Marcus' providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DrugProvider()),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.dashboard,
      routes: AppRoutes.routes,
      theme: AppTheme.theme,
      initialRoute: AppRoutes.login,
      routes: {
        //Marcus' routes
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
      },
    );
  }
}
