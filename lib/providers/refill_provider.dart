import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/refill_request.dart';

class RefillProvider extends ChangeNotifier {
  RefillProvider() {
    _sub = _db
        .collection('refill_requests')
        .orderBy('requestDateMs', descending: true)
        .snapshots()
        .listen(_onSnapshot, onError: (_) {});
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _sub;

  List<RefillRequest> _requests = [];
  bool _isLoading = true;

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
    _sub.cancel();
    super.dispose();
  }
}
