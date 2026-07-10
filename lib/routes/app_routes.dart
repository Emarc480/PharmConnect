import 'package:flutter/material.dart';

import '../screens/staff_dashboard.dart';
import '../screens/inventory_screen.dart';

class AppRoutes {
  static const dashboard = "/";
  static const inventory = "/inventory";
  static const orders = "/orders";

  static Map<String, WidgetBuilder> routes = {
    dashboard: (context) => const StaffDashboard(),
    inventory: (context) => const InventoryScreen(),
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