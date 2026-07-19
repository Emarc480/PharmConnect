import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/prescription_request.dart';

/// Firestore-backed prescription submissions (FR-style "Upload
/// Prescription"). Images are downsized client-side by the picker and
/// stored inline as base64 — small enough to stay well under
/// Firestore's 1MB document cap while avoiding a Cloud Storage
/// dependency for this prototype.
class PrescriptionProvider extends ChangeNotifier {
  PrescriptionProvider() {
    _sub = _db
        .collection('prescriptions')
        .orderBy('submittedAtMs', descending: true)
        .snapshots()
        .listen(_onSnapshot, onError: (_) {});
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _sub;

  List<PrescriptionRequest> _requests = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;

  /// All submissions, newest first — used by staff's Prescriptions inbox.
  List<PrescriptionRequest> get requests => List.unmodifiable(_requests);

  /// Just the signed-in customer's own submissions.
  List<PrescriptionRequest> get myRequests {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];
    return _requests.where((r) => r.requesterId == uid).toList();
  }

  int get pendingCount =>
      _requests.where((r) => r.status == PrescriptionStatus.pending).length;

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _requests =
        snapshot.docs.map((d) => PrescriptionRequest.fromMap(d.id, d.data())).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<PrescriptionRequest> submit({
    File? imageFile,
    String? typedOrder,
    String? notes,
    required String requesterName,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Cannot submit a prescription while signed out.');
    }
    if (imageFile == null && (typedOrder == null || typedOrder.trim().isEmpty)) {
      throw ArgumentError('Attach a photo or type the order first.');
    }

    _isSubmitting = true;
    notifyListeners();
    try {
      String? imageBase64;
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      final ref = _db.collection('prescriptions').doc();
      final request = PrescriptionRequest(
        id: ref.id,
        requesterId: uid,
        requesterName: requesterName,
        imageBase64: imageBase64,
        typedOrder: (typedOrder != null && typedOrder.trim().isNotEmpty) ? typedOrder.trim() : null,
        notes: (notes != null && notes.trim().isNotEmpty) ? notes.trim() : null,
        submittedAt: DateTime.now(),
      );
      await ref.set(request.toMap());
      return request;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(
    String id,
    PrescriptionStatus status, {
    String? pharmacistNote,
  }) async {
    await _db.collection('prescriptions').doc(id).update({
      'status': status.name,
      if (pharmacistNote != null) 'pharmacistNote': pharmacistNote,
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}