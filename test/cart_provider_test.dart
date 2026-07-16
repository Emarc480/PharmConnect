import 'package:flutter_test/flutter_test.dart';
import 'package:pharm_connect/models/drug.dart';
import 'package:pharm_connect/providers/cart_provider.dart';

void main() {
  const drug = Drug(
    id: 'a',
    name: 'Paracetamol',
    category: 'Pain Relief',
    price: 2000,
    stockQuantity: 100,
    reorderLevel: 10,
  );

  group('CartProvider', () {
    test('addToCart increases quantity and total', () {
      final cart = CartProvider();
      cart.addToCart(drug, quantity: 2);
      expect(cart.itemCount, 2);
      expect(cart.total, 4000);
    });

    test('adding the same drug twice accumulates quantity', () {
      final cart = CartProvider();
      cart.addToCart(drug);
      cart.addToCart(drug);
      expect(cart.quantityOf('a'), 2);
    });

    test('setQuantityById updates an existing line without needing the Drug', () {
      final cart = CartProvider();
      cart.addToCart(drug, quantity: 1);
      cart.setQuantityById('a', 5);
      expect(cart.quantityOf('a'), 5);
      expect(cart.total, 10000);
    });

    test('setting quantity to zero removes the item', () {
      final cart = CartProvider();
      cart.addToCart(drug, quantity: 3);
      cart.setQuantityById('a', 0);
      expect(cart.itemCount, 0);
      expect(cart.items, isEmpty);
    });

    test('clear empties the cart', () {
      final cart = CartProvider();
      cart.addToCart(drug, quantity: 4);
      cart.clear();
      expect(cart.itemCount, 0);
      expect(cart.total, 0);
    });
  });
}
