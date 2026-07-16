import 'package:flutter_test/flutter_test.dart';
import 'package:pharm_connect/models/drug.dart';
import 'package:pharm_connect/models/order.dart';

void main() {
  const drugA = Drug(
    id: 'a',
    name: 'Paracetamol',
    category: 'Pain Relief',
    price: 2000,
    stockQuantity: 100,
    reorderLevel: 10,
  );
  const drugB = Drug(
    id: 'b',
    name: 'Vitamin C',
    category: 'Vitamins',
    price: 12000,
    stockQuantity: 50,
    reorderLevel: 10,
  );

  group('OrderItem.subtotal (mirrors calculateTotal from the class diagram)', () {
    test('subtotal multiplies unit price by quantity', () {
      final item = OrderItem.fromDrug(drugA, 3);
      expect(item.subtotal, 6000);
    });
  });

  group('Order.total', () {
    test('sums subtotals across multiple line items', () {
      final order = Order(
        id: 'o1',
        customerId: 'u1',
        items: [
          OrderItem.fromDrug(drugA, 2), // 4,000
          OrderItem.fromDrug(drugB, 1), // 12,000
        ],
        orderDate: DateTime(2026, 7, 1),
        deliveryAddress: 'Kampala',
      );
      expect(order.total, 16000);
      expect(order.formattedTotal, 'UGX 16,000');
    });

    test('total is zero for an order with no items', () {
      final order = Order(
        id: 'o2',
        customerId: 'u1',
        items: const [],
        orderDate: DateTime(2026, 7, 1),
        deliveryAddress: 'Kampala',
      );
      expect(order.total, 0);
    });
  });

  group('OrderStatus.next (order lifecycle, FR10)', () {
    test('walks placed -> processing -> shipped -> delivered -> null', () {
      expect(OrderStatus.placed.next, OrderStatus.processing);
      expect(OrderStatus.processing.next, OrderStatus.shipped);
      expect(OrderStatus.shipped.next, OrderStatus.delivered);
      expect(OrderStatus.delivered.next, isNull);
    });
  });

  group('Order.fromMap/toMap round-trip', () {
    test('preserves items, status, and customer scoping', () {
      final order = Order(
        id: 'o3',
        customerId: 'u42',
        items: [OrderItem.fromDrug(drugA, 5)],
        orderDate: DateTime(2026, 7, 10),
        deliveryAddress: 'Entebbe',
        status: OrderStatus.processing,
      );
      final rebuilt = Order.fromMap('o3', order.toMap());
      expect(rebuilt.customerId, 'u42');
      expect(rebuilt.items.length, 1);
      expect(rebuilt.items.first.drugName, 'Paracetamol');
      expect(rebuilt.status, OrderStatus.processing);
      expect(rebuilt.total, 10000);
    });
  });
}
