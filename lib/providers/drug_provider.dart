import 'package:flutter/foundation.dart';
import '../models/drug.dart';

class DrugProvider extends ChangeNotifier {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<Drug> _drugs = [
    Drug(id: '1', name: 'Panadol 500mg', priceUgx: 5000, stockStatus: StockStatus.inStock, unitsAvailable: 120, category: 'Pain Relief'),
    Drug(id: '2', name: 'Amoxicillin 250mg', priceUgx: 12000, stockStatus: StockStatus.inStock, unitsAvailable: 60, category: 'Pain Relief'),
    Drug(id: '3', name: 'Vitamin C 1000mg', priceUgx: 8500, stockStatus: StockStatus.lowStock, unitsAvailable: 8, category: 'Vitamins'),
  ];

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<String> get categories => ['All', 'Pain Relief', 'Vitamins'];

  List<Drug> get filteredDrugs {
    return _drugs.where((drug) {
      final matchesSearch = drug.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || drug.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
}