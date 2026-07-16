import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

/// [unknown]  — still checking for a persisted session on cold start.
/// [unauthenticated] — no signed-in user; show LoginScreen.
/// [authenticating] — a login/register call is in flight.
/// [authenticated] — currentUser is populated; route by currentUser!.role.
/// [error] — last login/register attempt failed; see errorMessage.
enum AuthStatus { unknown, unauthenticated, authenticating, authenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    // Restores the signed-in session across app restarts (fixes the
    // "no persistence" gap for auth specifically): FirebaseAuth caches
    // credentials on-device, and this listener fires immediately with
    // the cached user, if any, every time the app cold-starts.
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isStaff => _currentUser?.role == UserRole.staff;

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) {
        // Auth account exists but the profile/role doc is missing —
        // treat as signed out rather than guessing a role.
        await _auth.signOut();
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      _currentUser = AppUser.fromMap(firebaseUser.uid, doc.data()!);
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Could not load your profile. Check your connection.';
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // _onAuthChanged will fire from the listener above and finish
      // populating currentUser/status; we just wait for it here too so
      // the caller's `await` returns only once currentUser is ready.
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _currentUser = AppUser.fromMap(user.uid, doc.data()!);
          _status = AuthStatus.authenticated;
          notifyListeners();
        }
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _messageFor(e);
      notifyListeners();
      return false;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Login failed. Please check your connection.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(name);

      final profile = AppUser(uid: uid, name: name, email: email, role: role);
      await _db.collection('users').doc(uid).set(profile.toMap());

      _currentUser = profile;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _messageFor(e);
      notifyListeners();
      return false;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Registration failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // _onAuthChanged listener sets status to unauthenticated.
  }

  void clearError() {
    if (_status == AuthStatus.error) {
      _status = _currentUser != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    }
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters).';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
