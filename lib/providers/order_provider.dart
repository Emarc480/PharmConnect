import 'package:flutter/foundation.dart';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];
  int _counter = 1042; // matches wireframe's sample order #1042

  List<Order> get orders => List.unmodifiable(_orders.reversed);

  List<Order> ordersByStatus(OrderStatus? status) {
    if (status == null) return orders;
    return orders.where((o) => o.status == status).toList();
  }

  Order placeOrder({
    required List<OrderItem> items,
    required String deliveryAddress,
  }) {
    final order = Order(
      id: '#${_counter++}',
      items: items,
      orderDate: DateTime.now(),
      deliveryAddress: deliveryAddress,
    );
    _orders.add(order);
    notifyListeners();
    return order;
  }

  void advanceStatus(String orderId) {
    final order = _orders.firstWhere((o) => o.id == orderId);
    final next = order.status.next;
    if (next != null) {
      order.status = next;
      order.lastUpdated = DateTime.now();
      notifyListeners();
    }
  }

  void cancelOrder(String orderId) {
    _orders.removeWhere((o) => o.id == orderId);
    notifyListeners();
  }

  Order? byId(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }
}
