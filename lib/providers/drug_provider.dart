import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/drug.dart';

/// Single provider for the `drugs` Firestore collection, used by BOTH
/// the customer catalog (Home/Browse, Drug Detail) and the staff
/// Inventory screen. This replaces the old DrugProvider + separate
/// InventoryProvider/Medicine split: there is now exactly one drug
/// record per drug, so a stock edit in Inventory is the same
/// stockQuantity the customer sees on the catalog (FR3 + FR8).
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
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<String> get categories => [
        'All',
        ..._drugs.map((d) => d.category).toSet().toList()..sort(),
      ];

  List<Drug> get allDrugs => List.unmodifiable(_drugs);

  List<Drug> get filteredDrugs {
    return _drugs.where((drug) {
      final matchesSearch =
          drug.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || drug.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  int get lowStockCount => _drugs.where((d) => d.isLowStock).length;

  List<Drug> get lowStockDrugs =>
      List.unmodifiable(_drugs.where((d) => d.isLowStock));

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
  }) async {
    final drug = Drug(
      id: '',
      name: name,
      category: category,
      description: description,
      price: price,
      stockQuantity: stockQuantity,
      reorderLevel: reorderLevel,
    );
    await _db.collection('drugs').add(drug.toMap());
    // The snapshot listener above will update _drugs automatically.
  }

  Future<void> updateDrug(Drug drug) async {
    await _db.collection('drugs').doc(drug.id).update(drug.toMap());
  }

  /// Adjusts stock atomically so concurrent staff edits (or a customer
  /// placing an order at the same time) can't silently overwrite each
  /// other — safer than a plain read-then-write.
  Future<void> adjustStock(String id, int change) async {
    final ref = _db.collection('drugs').doc(id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final current = ((snap.data()?['stockQuantity'] as num?) ?? 0).toInt();
      final updated = (current + change).clamp(0, 999999);
      tx.update(ref, {'stockQuantity': updated});
    });
  }

  Future<void> deleteDrug(String id) async {
    await _db.collection('drugs').doc(id).delete();
  }

  /// One-tap sample data for Day 3 of the coding outline — seeds
  /// 12 sample drugs across the wireframe's three categories. Only
  /// meant to be called once against an empty catalog (e.g. from a
  /// debug button), not part of the production data flow.
  Future<void> seedSampleCatalog() async {
    if (_drugs.isNotEmpty) return;
    final batch = _db.batch();
    final samples = <Drug>[
      const Drug(id: '', name: 'Paracetamol 500mg', category: 'Pain Relief', price: 2000, stockQuantity: 120, reorderLevel: 20, description: 'Pain and fever relief tablets.'),
      const Drug(id: '', name: 'Ibuprofen 400mg', category: 'Pain Relief', price: 3500, stockQuantity: 8, reorderLevel: 15, description: 'Anti-inflammatory pain reliever.'),
      const Drug(id: '', name: 'Aspirin 300mg', category: 'Pain Relief', price: 1500, stockQuantity: 60, reorderLevel: 15, description: 'Pain relief and blood thinner.'),
      const Drug(id: '', name: 'Amoxicillin 500mg', category: 'Antibiotics', price: 8000, stockQuantity: 40, reorderLevel: 10, description: 'Broad-spectrum antibiotic capsules.'),
      const Drug(id: '', name: 'Metronidazole 400mg', category: 'Antibiotics', price: 6000, stockQuantity: 0, reorderLevel: 10, description: 'Antibiotic for bacterial infections.'),
      const Drug(id: '', name: 'Doxycycline 100mg', category: 'Antibiotics', price: 9500, stockQuantity: 25, reorderLevel: 10, description: 'Antibiotic for a range of infections.'),
      const Drug(id: '', name: 'Vitamin C 1000mg', category: 'Vitamins', price: 12000, stockQuantity: 75, reorderLevel: 15, description: 'Immune support supplement.'),
      const Drug(id: '', name: 'Multivitamin Complex', category: 'Vitamins', price: 18000, stockQuantity: 30, reorderLevel: 10, description: 'Daily multivitamin and mineral tablets.'),
      const Drug(id: '', name: 'Vitamin D3 1000IU', category: 'Vitamins', price: 15000, stockQuantity: 9, reorderLevel: 10, description: 'Bone and immune health supplement.'),
      const Drug(id: '', name: 'Cough Syrup', category: 'Cold & Flu', price: 7000, stockQuantity: 45, reorderLevel: 10, description: 'Relieves cough and throat irritation.'),
      const Drug(id: '', name: 'Antihistamine Tablets', category: 'Cold & Flu', price: 4000, stockQuantity: 55, reorderLevel: 10, description: 'Allergy and cold symptom relief.'),
      const Drug(id: '', name: 'ORS Sachets', category: 'Cold & Flu', price: 1000, stockQuantity: 100, reorderLevel: 20, description: 'Oral rehydration salts.'),
    ];
    for (final drug in samples) {
      batch.set(_db.collection('drugs').doc(), drug.toMap());
    }
    await batch.commit();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
