import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/refill_request.dart';

/// Security rules only let a customer read their own `refill_requests`
/// docs, so the query must be scoped server-side with a `.where()` for
/// non-staff users — see the matching note on OrderProvider.
/// [updateAuth] is driven from a ChangeNotifierProxyProvider in
/// main.dart.
class RefillProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<RefillRequest> _requests = [];
  bool _isLoading = true;
  String? _uid;
  bool _isStaff = false;

  bool get isLoading => _isLoading;

  /// All requests, newest first — used by staff's Refill Management screen.
  List<RefillRequest> get requests => List.unmodifiable(_requests);

  /// Just the signed-in customer's own requests — used by the
  /// customer-facing Refill Request screen (FR4).
  List<RefillRequest> get myRequests {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];
    return _requests.where((r) => r.requesterId == uid).toList();
  }

  /// Restarts the Firestore listener with a query matching the current
  /// user's role. Call this whenever auth state (uid or isStaff)
  /// changes; a no-op if nothing actually changed.
  void updateAuth({required String? uid, required bool isStaff}) {
    if (_uid == uid && _isStaff == isStaff) return;
    _uid = uid;
    _isStaff = isStaff;
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    if (_uid == null) {
      _requests = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    final Query<Map<String, dynamic>> query = _isStaff
        ? _db
            .collection('refill_requests')
            .orderBy('requestDateMs', descending: true)
        : _db
            .collection('refill_requests')
            .where('requesterId', isEqualTo: _uid)
            .orderBy('requestDateMs', descending: true);

    _sub = query.snapshots().listen(_onSnapshot, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  int get pendingCount =>
      _requests.where((r) => r.status == RefillStatus.pending).length;

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _requests = snapshot.docs
        .map((d) => RefillRequest.fromMap(d.id, d.data()))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<RefillRequest> submitRequest({
    required String drugName,
    String? notes,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Cannot submit a refill request while signed out.');
    }
    final ref = _db.collection('refill_requests').doc();
    final request = RefillRequest(
      id: ref.id,
      requesterId: uid,
      drugName: drugName,
      notes: notes,
      requestDate: DateTime.now(),
    );
    await ref.set(request.toMap());
    return request;
  }

  Future<void> updateStatus(String id, RefillStatus status) async {
    await _db.collection('refill_requests').doc(id).update({
      'status': status.name,
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}