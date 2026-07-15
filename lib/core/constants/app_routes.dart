import 'package:flutter/material.dart';

import '../../models/drug.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/staff_dashboard.dart';
import '../../screens/inventory_screen.dart';
import '../../screens/drug_detail_screen.dart';
import '../../screens/cart_screen.dart';
import '../../screens/order_tracking_screen.dart';
import '../../screens/order_management_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String dashboard = '/';
  static const String inventory = '/inventory';
  static const String orders = '/orders';
  static const String drugDetail = '/drug-detail';
  static const String cart = '/cart';
  static const String orderTracking = '/order-tracking';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    home: (context) => const HomeScreen(),
    dashboard: (context) => const StaffDashboard(),
    inventory: (context) => const InventoryScreen(),
    orders: (context) => const OrderManagementScreen(),
    cart: (context) => const CartScreen(),
  };

  /// Handles routes that need arguments (drug object, order id).
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case drugDetail:
        final drug = settings.arguments as Drug;
        return MaterialPageRoute(
          builder: (context) => DrugDetailScreen(drug: drug),
        );
      case orderTracking:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => OrderTrackingScreen(orderId: orderId),
        );
      default:
        return null;
    }
  }
}
