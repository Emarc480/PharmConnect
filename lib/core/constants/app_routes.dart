import 'package:flutter/material.dart';

import '../../models/drug.dart';
import '../../screens/auth/auth_gate.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/staff_home_shell.dart';
import '../../screens/inventory_screen.dart';
import '../../screens/drug_detail_screen.dart';
import '../../screens/cart_screen.dart';
import '../../screens/payment_screen.dart';
import '../../screens/order_tracking_screen.dart';
import '../../screens/order_management_screen.dart';
import '../../screens/orders_list_screen.dart';
import '../../screens/refill_request_screen.dart';
import '../../screens/refill_management_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/prescription_upload_screen.dart';
import '../../screens/reminders_screen.dart';
import '../../screens/ai_pharmacist_screen.dart';
import '../../screens/prescription_management_screen.dart';
import '../../widgets/role_guard.dart';
import '../../screens/app_settings_screen.dart';
import '../../screens/promo_banner_management_screen.dart';
import '../../screens/reports_screen.dart';
import '../../screens/stock_history_screen.dart';
import '../../screens/staff_notifications_screen.dart';
import '../../screens/staff_management_screen.dart';

class AppRoutes {
  /// Root route: decides between Login / Home / Staff Dashboard based on
  /// the restored (or fresh) auth session — see AuthGate.
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String staffDashboard = '/staff-dashboard';
  static const String inventory = '/inventory';
  static const String orders = '/orders';
  static const String drugDetail = '/drug-detail';
  static const String cart = '/cart';
  static const String payment = '/payment';
  static const String orderTracking = '/order-tracking';
  static const String myOrders = '/my-orders';
  static const String refill = '/refill';
  static const String refillManagement = '/refill-management';
  static const String profile = '/profile';
  static const String prescription = '/prescription';
  static const String reminders = '/reminders';
  static const String askPharmacist = '/ask-pharmacist';
  static const String prescriptionManagement = '/prescription-management';
  static const String appSettings = '/app-settings';
  static const String promoBannerManagement = '/promo-banner-management';
  static const String reports = '/reports';
  static const String stockHistory = '/stock-history';
  static const String staffNotifications = '/staff-notifications';
  static const String staffManagement = '/staff-management';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const AuthGate(),
    login: (context) => const LoginScreen(),
    home: (context) => const HomeScreen(),
    staffDashboard: (context) => const StaffOnly(child: StaffHomeShell()),
    inventory: (context) => const StaffOnly(child: InventoryScreen()),
    orders: (context) => const StaffOnly(child: OrderManagementScreen()),
    cart: (context) => const CartScreen(),
    myOrders: (context) => const OrdersListScreen(),
    refill: (context) => const RefillRequestScreen(),
    refillManagement: (context) => const StaffOnly(child: RefillManagementScreen()),
    profile: (context) => const ProfileScreen(),
    prescription: (context) => const PrescriptionUploadScreen(),
    reminders: (context) => const RemindersScreen(),
    askPharmacist: (context) => const AiPharmacistScreen(),
    prescriptionManagement: (context) => const StaffOnly(child: PrescriptionManagementScreen()),
    appSettings: (context) => const AppSettingsScreen(),
    promoBannerManagement: (context) => const StaffOnly(child: PromoBannerManagementScreen()),
    reports: (context) => const StaffOnly(child: ReportsScreen()),
    stockHistory: (context) => const StaffOnly(child: StockHistoryScreen()),
    staffNotifications: (context) => const StaffOnly(child: StaffNotificationsScreen()),
    staffManagement: (context) => const AdminOnly(child: StaffManagementScreen()),
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
      case payment:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => PaymentScreen(
            orderId: args['orderId'] as String,
            amount: (args['amount'] as num).toDouble(),
          ),
        );
      default:
        return null;
    }
  }
}