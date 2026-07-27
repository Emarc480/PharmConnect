import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/drug.dart';
import '../core/constants/drug_categories.dart';

enum DrugSortOption { relevance, priceLowToHigh, priceHighToLow, nameAZ }

extension DrugSortOptionLabel on DrugSortOption {
  String get label {
    switch (this) {
      case DrugSortOption.relevance:
        return 'Relevance';
      case DrugSortOption.priceLowToHigh:
        return 'Price: Low to High';
      case DrugSortOption.priceHighToLow:
        return 'Price: High to Low';
      case DrugSortOption.nameAZ:
        return 'Name: A to Z';
    }
  }
}

/// Single provider for the `drugs` Firestore collection, used by BOTH
/// the customer catalog (Home/Browse, Drug Detail) and the staff
/// Inventory screen.
class DrugProvider extends ChangeNotifier {
  DrugProvider() {
    _sub = _db
        .collection('drugs')
        .orderBy('name')
        .snapshots()
        .listen(_onSnapshot, onError: (_) {
      // Keep whatever we last had cached; UI shows stale-but-present
      // data rather than clearing the screen on a transient error.
    });
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _sub;

  List<Drug> _drugs = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  DrugSortOption _sortOption = DrugSortOption.relevance;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  DrugSortOption get sortOption => _sortOption;

  /// Fixed list of the 18 pharmacy-wide categories, not derived from
  /// whatever drugs currently exist — so every category shows up in
  /// the filter (and can be picked when adding a drug) even before
  /// the first drug in it has been added.
  List<String> get categories => ['All', ...kDrugCategories];

  List<Drug> get allDrugs => List.unmodifiable(_drugs);

  List<Drug> get filteredDrugs {
    final results = _drugs.where((drug) {
      final matchesSearch =
          drug.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || drug.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    switch (_sortOption) {
      case DrugSortOption.relevance:
        break;
      case DrugSortOption.priceLowToHigh:
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case DrugSortOption.priceHighToLow:
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case DrugSortOption.nameAZ:
        results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    return results;
  }

  List<Drug> get discountedDrugs =>
      List.unmodifiable(_drugs.where((d) => d.hasDiscount));

  int get lowStockCount => _drugs.where((d) => d.isLowStock).length;

  List<Drug> get lowStockDrugs =>
      List.unmodifiable(_drugs.where((d) => d.isLowStock));

  int get outOfStockCount => _drugs.where((d) => d.stockQuantity <= 0).length;

  int get expiringSoonCount => _drugs.where((d) => d.isExpiringSoon).length;

  List<Drug> get expiringSoonDrugs =>
      List.unmodifiable(_drugs.where((d) => d.isExpiringSoon));

  int get expiredCount => _drugs.where((d) => d.isExpired).length;

  List<Drug> get expiredDrugs =>
      List.unmodifiable(_drugs.where((d) => d.isExpired));

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _drugs = snapshot.docs.map((d) => Drug.fromMap(d.id, d.data())).toList();
    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortOption(DrugSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  Drug? byId(String id) {
    try {
      return _drugs.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addDrug({
    required String name,
    required String category,
    required int stockQuantity,
    required int reorderLevel,
    required double price,
    String description = '',
    int discountPercent = 0,
    String? imageBase64,
    String? countryOfOrigin,
    String? manufacturerName,
    DateTime? expiryDate,
    String? batchNumber,
  }) async {
    final drug = Drug(
      id: '',
      name: name,
      category: category,
      description: description,
      price: price,
      stockQuantity: stockQuantity,
      reorderLevel: reorderLevel,
      discountPercent: discountPercent,
      imageBase64: imageBase64,
      countryOfOrigin: countryOfOrigin,
      manufacturerName: manufacturerName,
      expiryDate: expiryDate,
      batchNumber: batchNumber,
    );
    await _db.collection('drugs').add(drug.toMap());
  }

  Future<void> updateDrug(Drug drug) async {
    await _db.collection('drugs').doc(drug.id).update(drug.toMap());
  }

  /// Applies [change] to a drug's stockQuantity and returns the
  /// resulting value (clamped to >= 0), so callers — e.g. the
  /// Inventory stepper, restock sheet, and stock adjustment log — can
  /// record an accurate [StockMovement.resultingStock] without a
  /// second read.
  Future<int> adjustStock(String id, int change) async {
    final ref = _db.collection('drugs').doc(id);
    return _db.runTransaction<int>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return 0;
      final current = ((snap.data()?['stockQuantity'] as num?) ?? 0).toInt();
      final updated = (current + change).clamp(0, 999999);
      tx.update(ref, {'stockQuantity': updated});
      return updated;
    });
  }

  Future<void> deleteDrug(String id) async {
    await _db.collection('drugs').doc(id).delete();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}