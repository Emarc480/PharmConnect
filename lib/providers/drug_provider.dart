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
    );
    await _db.collection('drugs').add(drug.toMap());
  }

  Future<void> updateDrug(Drug drug) async {
    await _db.collection('drugs').doc(drug.id).update(drug.toMap());
  }

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

  /// Seeds the catalog from the 18-category reference list — every
  /// medicine, country, and manufacturer noted goes into the
  /// description field. Stock/price/reorder values are reasonable
  /// placeholders for demo purposes (a few are deliberately set low
  /// or to zero so the Low Stock / Out of Stock states have
  /// something to show), and a handful carry a discount so the Home
  /// "Offers" rail isn't empty. Only runs once against an empty
  /// catalog.
  Future<void> seedSampleCatalog() async {
    if (_drugs.isNotEmpty) return;
    final batch = _db.batch();

    Drug d(String name, String category, String desc, double price, int stock, {int reorder = 15, int discount = 0}) {
      return Drug(id: '', name: name, category: category, description: desc, price: price, stockQuantity: stock, reorderLevel: reorder, discountPercent: discount);
    }

    final samples = <Drug>[
      // 1. Pain & Fever
      d('Paracetamol', 'Pain & Fever', 'Common manufacturers: Cipla, Sun Pharma, Micro Labs (India).', 2000, 150, discount: 15),
      d('Ibuprofen', 'Pain & Fever', 'Common manufacturers: Alkem, Intas (India).', 3500, 90),
      d('Diclofenac', 'Pain & Fever', 'Common manufacturers: Lupin, Cipla (India).', 4000, 60),
      d('Aspirin', 'Pain & Fever', 'Manufactured in Germany by Bayer.', 3000, 8, reorder: 15),
      d('Tramadol', 'Pain & Fever', 'Common manufacturers: Sun Pharma, Zydus (India).', 6000, 30),

      // 2. Antibiotics
      d('Amoxicillin', 'Antibiotics', 'Common manufacturers: Cipla, Mankind, Alkem (India).', 8000, 70, discount: 10),
      d('Azithromycin', 'Antibiotics', 'Common manufacturers: Sun Pharma, Lupin (India).', 9500, 45),
      d('Ciprofloxacin', 'Antibiotics', 'Common manufacturers: Cipla, Intas (India).', 7000, 55),
      d('Metronidazole', 'Antibiotics', 'Manufactured in Uganda and India by Rene Industries, Cipla.', 5000, 0, reorder: 10),
      d('Ceftriaxone', 'Antibiotics', 'Common manufacturers: Alkem, Lupin (India).', 12000, 20),
      d('Co-trimoxazole (Septrin)', 'Antibiotics', 'Manufactured in Uganda and India by Rene Industries, Cipla.', 4500, 80),

      // 3. Antimalarials
      d('Artemether-Lumefantrine', 'Antimalarials', 'Manufactured in Uganda and India by Qcil, Cipla.', 10000, 100, discount: 10),
      d('Quinine', 'Antimalarials', 'Manufactured in Uganda by Rene Industries.', 6000, 25),
      d('Artesunate', 'Antimalarials', 'Common manufacturers: Cipla (India), Guilin (China).', 15000, 12, reorder: 15),
      d('Fansidar', 'Antimalarials', 'Manufactured in France by Sanofi.', 5000, 40),

      // 4. Dewormers
      d('Albendazole', 'Dewormers', 'Common manufacturers: Cipla, Alkem (India).', 2500, 60),
      d('Mebendazole', 'Dewormers', 'Common manufacturers: Janssen, Cipla (India).', 2000, 50),
      d('Praziquantel', 'Dewormers', 'Manufactured in India by Lupin.', 3500, 30),
      d('Ivermectin', 'Dewormers', 'Manufactured in India by Sun Pharma.', 4000, 20),

      // 5. HIV (ARVs)
      d('Tenofovir/Lamivudine/Dolutegravir (TLD)', 'HIV (ARVs)', 'Manufactured in Uganda and India by Qcil, Cipla, Mylan/Viatris.', 0, 200, reorder: 30),
      d('Zidovudine', 'HIV (ARVs)', 'Manufactured in India by Cipla.', 0, 60, reorder: 15),

      // 6. TB Medicines
      d('RHZE Combination', 'TB Medicines', 'Manufactured in Uganda and India by Qcil, Macleods.', 0, 90, reorder: 20),

      // 7. Cough & Cold
      d('Salbutamol Syrup', 'Cough & Cold', 'Manufactured in India by Cipla.', 4500, 45),
      d('Salbutamol Inhaler', 'Cough & Cold', 'Manufactured in India by Cipla.', 15000, 25),
      d('Cough Syrups', 'Cough & Cold', 'Manufactured in Uganda by Rene Industries, Abacus Pharma.', 5000, 70, discount: 10),

      // 8. Allergy
      d('Cetirizine', 'Allergy', 'Common manufacturers: Sun Pharma, Cipla (India).', 2500, 65),
      d('Loratadine', 'Allergy', 'Manufactured in India by Intas.', 3000, 40),
      d('Chlorpheniramine', 'Allergy', 'Manufactured in India by Alkem.', 1500, 55),

      // 9. Stomach
      d('Omeprazole', 'Stomach', 'Common manufacturers: Dr. Reddy\'s, Cipla (India).', 4000, 75),
      d('Pantoprazole', 'Stomach', 'Manufactured in India by Sun Pharma.', 4500, 50),
      d('ORS Sachets', 'Stomach', 'Manufactured in Uganda by Joint Medical Stores and local suppliers.', 1000, 120, reorder: 20),
      d('Zinc Tablets', 'Stomach', 'Manufactured in Uganda by Qcil, Rene Industries.', 2000, 60),
      d('Loperamide', 'Stomach', 'Manufactured in India by Cipla.', 2500, 35),

      // 10. Diabetes
      d('Metformin', 'Diabetes', 'Common manufacturers: Sun Pharma, Lupin (India).', 5000, 55),
      d('Glibenclamide', 'Diabetes', 'Manufactured in India by Cipla.', 4000, 30),
      d('Insulin', 'Diabetes', 'Manufactured in Denmark by Novo Nordisk.', 25000, 10, reorder: 12),

      // 11. Blood Pressure
      d('Amlodipine', 'Blood Pressure', 'Common manufacturers: Cipla, Lupin (India).', 5000, 60),
      d('Losartan', 'Blood Pressure', 'Manufactured in India by Sun Pharma.', 6000, 45),
      d('Enalapril', 'Blood Pressure', 'Manufactured in India by Intas.', 4500, 40),
      d('Hydrochlorothiazide', 'Blood Pressure', 'Manufactured in India by Cipla.', 3500, 50),

      // 12. Heart
      d('Atorvastatin', 'Heart', 'Manufactured in India by Sun Pharma.', 8000, 35),
      d('Clopidogrel', 'Heart', 'Manufactured in India by Lupin.', 9000, 20),
      d('Furosemide', 'Heart', 'Manufactured in India by Cipla.', 3000, 45),

      // 13. Women's Health
      d('Oxytocin', "Women's Health", 'Manufactured in India by Neon Laboratories.', 6000, 25, reorder: 10),
      d('Misoprostol', "Women's Health", 'Manufactured in India by Cipla.', 7000, 20, reorder: 10),
      d('Folic Acid', "Women's Health", 'Manufactured in Uganda by Rene Industries.', 1500, 80),
      d('Iron Tablets', "Women's Health", 'Manufactured in Uganda by Rene Industries.', 2000, 90),
      d('Depo-Provera', "Women's Health", 'Manufactured in Belgium by Pfizer.', 12000, 15, reorder: 12),

      // 14. Children's Medicines
      d('Paracetamol Syrup', "Children's Medicines", 'Manufactured in Uganda and India by Rene Industries, Cipla.', 3500, 70, discount: 10),
      d('Amoxicillin Syrup', "Children's Medicines", 'Manufactured in India by Cipla.', 6000, 55),
      d('Vitamin A', "Children's Medicines", 'Supplied in Uganda via Ministry of Health suppliers.', 0, 100, reorder: 20),

      // 15. Skin Medicines
      d('Clotrimazole Cream', 'Skin Medicines', 'Manufactured in India by Cipla.', 4000, 40),
      d('Hydrocortisone Cream', 'Skin Medicines', 'Manufactured in India by Sun Pharma.', 4500, 30),
      d('Silver Sulfadiazine', 'Skin Medicines', 'Manufactured in India by Alkem.', 6000, 20),

      // 16. Eye & Ear
      d('Chloramphenicol Eye Drops', 'Eye & Ear', 'Manufactured in India by Cipla.', 3500, 35),
      d('Gentamicin Eye Drops', 'Eye & Ear', 'Manufactured in India by Intas.', 4000, 25),
      d('Ciprofloxacin Eye Drops', 'Eye & Ear', 'Manufactured in India by Sun Pharma.', 5000, 20),

      // 17. Vitamins & Supplements
      d('Vitamin C', 'Vitamins & Supplements', 'Common manufacturers: Himalaya, Cipla (India).', 8000, 65, discount: 20),
      d('Vitamin B Complex', 'Vitamins & Supplements', 'Manufactured in India by Alkem.', 7000, 55),
      d('Calcium', 'Vitamins & Supplements', 'Manufactured in India by Cipla.', 6500, 45),
      d('Multivitamins', 'Vitamins & Supplements', 'Manufactured in Uganda and India by Rene Industries, Cipla.', 12000, 40, discount: 10),

      // 18. Emergency Medicines
      d('Adrenaline', 'Emergency Medicines', 'Manufactured in Germany by B. Braun.', 15000, 10, reorder: 10),
      d('Diazepam Injection', 'Emergency Medicines', 'Manufactured in India by Neon Laboratories.', 8000, 15, reorder: 10),
      d('Atropine', 'Emergency Medicines', 'Manufactured in India by Samarth Life Sciences.', 9000, 12, reorder: 10),
      d('Magnesium Sulfate', 'Emergency Medicines', 'Manufactured in India by Neon Laboratories.', 5000, 18, reorder: 10),
      d('Dextrose IV', 'Emergency Medicines', 'Manufactured in Kenya and Uganda by Laboratory & Allied and local IV fluid manufacturers.', 4000, 30, reorder: 15),
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