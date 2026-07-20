import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../staff_home_shell.dart';
import 'login_screen.dart';

/// The app's actual root content (mounted at AppRoutes.splash = '/').
///
/// This is what fixes both the persistence gap and the RBAC gap for
/// login: instead of `main.dart` always opening on LoginScreen, this
/// widget watches AuthProvider and renders whichever screen matches
/// the *real*, restored session state:
///   - unknown          -> a brief splash while Firebase restores the
///                         cached session from disk
///   - unauthenticated   -> LoginScreen
///   - authenticated     -> HomeScreen (customer) or StaffHomeShell
///                         (staff), chosen by the user's stored role —
///                         there is no way to land on the wrong one.
///
/// Because these are swapped in place (not pushed), signing out just
/// needs to clear the auth session; this widget rebuilds to LoginScreen
/// automatically without any manual Navigator call from ProfileScreen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.unauthenticated:
      case AuthStatus.authenticating:
      case AuthStatus.error:
        return const LoginScreen();
      case AuthStatus.authenticated:
        final user = auth.currentUser;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return user.role == UserRole.staff
            ? const StaffHomeShell()
            : const HomeScreen();
    }
  }
}