import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/promo_banner.dart';

/// Single provider for the `promo_banners` Firestore collection, used
/// by both the customer Home carousel (read-only) and the staff
/// Promo Banner Management screen (read/write). Mirrors DrugProvider's
/// snapshot-listener pattern so every signed-in device sees the same
/// banners live, without a manual refresh.
class PromoBannerProvider extends ChangeNotifier {
  static const int maxSlots = 5;

  PromoBannerProvider() {
    _sub = _db
        .collection('promo_banners')
        .orderBy('order')
        .snapshots()
        .listen(_onSnapshot, onError: (_) {
      // Keep whatever we last had cached; UI shows stale-but-present
      // data rather than clearing the screen on a transient error.
    });
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _sub;

  List<PromoBanner> _banners = [];
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  List<PromoBanner> get banners => List.unmodifiable(_banners);

  /// The banner currently occupying a given slot (0-4), or null if
  /// that slot is empty.
  PromoBanner? bannerForSlot(int slotIndex) {
    for (final b in _banners) {
      if (b.order == slotIndex) return b;
    }
    return null;
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _banners = snapshot.docs
        .map((d) => PromoBanner.fromMap(d.id, d.data()))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  /// Creates or replaces the image in a slot (0-4).
  Future<void> setSlot(int slotIndex, String imageBase64) async {
    final existing = bannerForSlot(slotIndex);
    if (existing != null) {
      await _db.collection('promo_banners').doc(existing.id).update({
        'imageBase64': imageBase64,
      });
    } else {
      await _db.collection('promo_banners').add({
        'order': slotIndex,
        'imageBase64': imageBase64,
      });
    }
  }

  /// Empties a slot entirely (removes the document).
  Future<void> clearSlot(int slotIndex) async {
    final existing = bannerForSlot(slotIndex);
    if (existing != null) {
      await _db.collection('promo_banners').doc(existing.id).delete();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}