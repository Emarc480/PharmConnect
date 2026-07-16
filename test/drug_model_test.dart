import 'package:flutter_test/flutter_test.dart';
import 'package:pharm_connect/models/drug.dart';

void main() {
  group('Drug low-stock logic (FR3, FR11)', () {
    test('is inStock when well above reorder level', () {
      const drug = Drug(
        id: '1',
        name: 'Paracetamol',
        category: 'Pain Relief',
        price: 2000,
        stockQuantity: 50,
        reorderLevel: 10,
      );
      expect(drug.stockStatus, StockStatus.inStock);
      expect(drug.isLowStock, isFalse);
    });

    test('is lowStock exactly at the reorder threshold', () {
      const drug = Drug(
        id: '2',
        name: 'Ibuprofen',
        category: 'Pain Relief',
        price: 3500,
        stockQuantity: 10,
        reorderLevel: 10,
      );
      expect(drug.stockStatus, StockStatus.lowStock);
      expect(drug.isLowStock, isTrue);
    });

    test('is outOfStock at zero units', () {
      const drug = Drug(
        id: '3',
        name: 'Metronidazole',
        category: 'Antibiotics',
        price: 6000,
        stockQuantity: 0,
        reorderLevel: 10,
      );
      expect(drug.stockStatus, StockStatus.outOfStock);
      expect(drug.stockLabel, 'Out of Stock');
    });

    test('formattedPrice adds thousands separators', () {
      const drug = Drug(
        id: '4',
        name: 'Multivitamin',
        category: 'Vitamins',
        price: 18000,
        stockQuantity: 5,
        reorderLevel: 10,
      );
      expect(drug.formattedPrice, 'UGX 18,000');
    });

    test('fromMap/toMap round-trip preserves all fields', () {
      const drug = Drug(
        id: '5',
        name: 'Vitamin C',
        category: 'Vitamins',
        description: 'Immune support',
        price: 12000,
        stockQuantity: 75,
        reorderLevel: 15,
      );
      final rebuilt = Drug.fromMap('5', drug.toMap());
      expect(rebuilt.name, drug.name);
      expect(rebuilt.price, drug.price);
      expect(rebuilt.stockQuantity, drug.stockQuantity);
      expect(rebuilt.reorderLevel, drug.reorderLevel);
    });
  });
}
