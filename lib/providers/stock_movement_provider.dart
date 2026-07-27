import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/stock_movement.dart';

/// Staff-only, collection-wide audit log of every stock change.
/// Single `orderBy('timestampMs')` with no extra `.where()` — same
/// "avoid composite indexes" approach used elsewhere in this app (see
/// AiPharmacistProvider) — so per-drug history is filtered client-side
/// from this one cached, already-sorted list instead of firing a
/// second Firestore query.
class StockMovementProvider extends ChangeNotifier {
  StockMovementProvider() {
    _sub = _db
        .collection('stock_movements')
        .orderBy('timestampMs', descending: true)
        .limit(300)
        .snapshots()
        .listen(_onSnapshot, onError: (_) {
      // Keep whatever was last cached rather than clearing the screen.
    });
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _sub;

  List<StockMovement> _movements = [];
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  List<StockMovement> get movements => List.unmodifiable(_movements);

  List<StockMovement> movementsForDrug(String drugId) =>
      List.unmodifiable(_movements.where((m) => m.drugId == drugId));

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _movements = snapshot.docs.map((d) => StockMovement.fromMap(d.id, d.data())).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logMovement({
    required String drugId,
    required String drugName,
    required int delta,
    required int resultingStock,
    required StockMovementReason reason,
    required String staffId,
    required String staffName,
    String? supplierName,
    String? note,
  }) async {
    final movement = StockMovement(
      id: '',
      drugId: drugId,
      drugName: drugName,
      delta: delta,
      resultingStock: resultingStock,
      reason: reason,
      staffId: staffId,
      staffName: staffName,
      supplierName: supplierName,
      note: note,
      timestamp: DateTime.now(),
    );
    await _db.collection('stock_movements').add(movement.toMap());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
