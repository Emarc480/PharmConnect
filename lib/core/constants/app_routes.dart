import 'package:flutter/material.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/staff_dashboard.dart';
import '../../screens/inventory_screen.dart';
import '../../screens/profile/profile_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String inventory = '/inventory';
  static const String orders = '/orders';
  static const String profile = '/profile';
  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    home: (context) => const HomeScreen(),
    dashboard: (context) => const StaffDashboard(),
    inventory: (context) => const InventoryScreen(),
    profile: (context) => const ProfileScreen(),
    orders: (context) => const _OrdersPlaceholder(),
  };
}

class _OrdersPlaceholder extends StatelessWidget {
  const _OrdersPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orders")),
      body: const Center(
        child: Text("Order Management — coming soon"),
      ),
    );
  }
}