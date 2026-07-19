import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Per-customer saved/favourited drugs (the heart icon on product
/// cards). Stored as a single array field on one doc per user —
/// wishlists are small, so this avoids a subcollection for something
/// this simple.
class WishlistProvider extends ChangeNotifier {
  WishlistProvider() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  Set<String> _drugIds = {};

  Set<String> get drugIds => Set.unmodifiable(_drugIds);

  bool isSaved(String drugId) => _drugIds.contains(drugId);

  void _onAuthChanged(User? user) {
    _sub?.cancel();
    if (user == null) {
      _drugIds = {};
      notifyListeners();
      return;
    }
    _sub = _db.collection('wishlists').doc(user.uid).snapshots().listen((snap) {
      final ids = (snap.data()?['drugIds'] as List<dynamic>?) ?? const [];
      _drugIds = ids.map((e) => e.toString()).toSet();
      notifyListeners();
    }, onError: (_) {});
  }

  Future<void> toggle(String drugId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = _db.collection('wishlists').doc(uid);
    final isCurrentlySaved = _drugIds.contains(drugId);
    // Optimistic local update so the heart responds instantly.
    if (isCurrentlySaved) {
      _drugIds.remove(drugId);
    } else {
      _drugIds.add(drugId);
    }
    notifyListeners();
    await ref.set({
      'drugIds': isCurrentlySaved
          ? FieldValue.arrayRemove([drugId])
          : FieldValue.arrayUnion([drugId]),
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}