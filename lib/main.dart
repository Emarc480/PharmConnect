import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/inventory_provider.dart';
import 'routes/app_routes.dart';

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
    );
  }
}
