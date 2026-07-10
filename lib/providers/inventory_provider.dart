import 'package:flutter/material.dart';

import '../models/medicine.dart';

class InventoryProvider extends ChangeNotifier {
  final List<Medicine> _medicines = [
    const Medicine(
      id: 'med-001',
      name: 'Panadol 500mg',
      category: 'Pain relief',
      stock: 120,
      reorderLevel: 30,
      price: 10000,
    ),
    const Medicine(
      id: 'med-002',
      name: 'Amoxicillin 250mg',
      category: 'Antibiotics',
      stock: 60,
      reorderLevel: 70,
      price: 12000,
    ),
    const Medicine(
      id: 'med-003',
      name: 'Vitamin C 1000mg',
      category: 'Supplements',
      stock: 8,
      reorderLevel: 20,
      price: 8500,
    ),
    const Medicine(
      id: 'med-004',
      name: 'Cough Syrup 100ml',
      category: 'Cold and flu',
      stock: 45,
      reorderLevel: 50,
      price: 7000,
    ),
  ];

  List<Medicine> get medicines => List.unmodifiable(_medicines);

  int get totalMedicines => _medicines.length;

  int get totalStock => _medicines.fold(
        0,
        (total, medicine) => total + medicine.stock,
      );

  int get lowStockCount => _medicines
      .where(
        (medicine) => medicine.isLowStock,
      )
      .length;

  List<Medicine> get lowStockMedicines => List.unmodifiable(
        _medicines.where((medicine) => medicine.isLowStock),
      );

  void addMedicine({
    required String name,
    required String category,
    required int stock,
    required int reorderLevel,
    required double price,
  }) {
    _medicines.add(
      Medicine(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        category: category,
        stock: stock,
        reorderLevel: reorderLevel,
        price: price,
      ),
    );

    notifyListeners();
  }

  void adjustStock(String id, int change) {
    final index = _medicines.indexWhere(
      (medicine) => medicine.id == id,
    );

    if (index == -1) {
      return;
    }

    final medicine = _medicines[index];
    final updatedStock = (medicine.stock + change).clamp(0, 999999).toInt();
    _medicines[index] = medicine.copyWith(stock: updatedStock);

    notifyListeners();
  }
}
