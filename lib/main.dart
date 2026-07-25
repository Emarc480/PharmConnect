import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/drug_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/refill_provider.dart';
import 'providers/prescription_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/pharmacist_chat_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'providers/promo_banner_provider.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DrugProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
        // OrderProvider/RefillProvider need to know the signed-in
        // user's uid + role to build a query that satisfies Firestore
        // security rules (customers can only list their own docs).
        // The proxy re-runs updateAuth() whenever AuthProvider changes,
        // which restarts the Firestore listener with the right query.
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(),
          update: (_, auth, order) =>
              order!
                ..updateAuth(uid: auth.currentUser?.uid, isStaff: auth.isStaff),
        ),
        ChangeNotifierProxyProvider<AuthProvider, RefillProvider>(
          create: (_) => RefillProvider(),
          update: (_, auth, refill) =>
              refill!
                ..updateAuth(uid: auth.currentUser?.uid, isStaff: auth.isStaff),
        ),
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => PharmacistChatProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => PromoBannerProvider()),
      ],
      child: const PharmConnectApp(),
    ),
  );
}

class PharmConnectApp extends StatelessWidget {
  const PharmConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeModeProvider>().themeMode;
    
    return MaterialApp(
      title: 'PharmConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // The splash route ('/') now renders AuthGate, which decides
      // Login vs Home vs Staff Dashboard from the restored session —
      // see lib/screens/auth/auth_gate.dart for why this fixes both
      // the persistence and RBAC-routing gaps at once.
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
    );
  }
}