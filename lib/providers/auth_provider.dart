import 'package:flutter/foundation.dart';

enum AuthStatus { idle, loading, authenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      // TODO: replace with real call to your backend's login endpoint
      await Future.delayed(const Duration(seconds: 1));
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Login failed. Please check your credentials.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      // TODO: replace with real call to your backend's register endpoint
      await Future.delayed(const Duration(seconds: 1));
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Registration failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void continueAsGuest() {
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void reset() {
    _status = AuthStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}