import 'drug.dart';

enum OrderStatus { placed, processing, shipped, delivered }

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  OrderStatus? get next {
    switch (this) {
      case OrderStatus.placed:
        return OrderStatus.processing;
      case OrderStatus.processing:
        return OrderStatus.shipped;
      case OrderStatus.shipped:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
        return null;
    }
  }
}

class OrderItem {
  final Drug drug;
  final int quantity;

  OrderItem({required this.drug, required this.quantity});

  int get subtotal => drug.priceUgx * quantity;
}

class Order {
  final String id;
  final List<OrderItem> items;
  final DateTime orderDate;
  final String deliveryAddress;
  OrderStatus status;
  DateTime lastUpdated;

  Order({
    required this.id,
    required this.items,
    required this.orderDate,
    required this.deliveryAddress,
    this.status = OrderStatus.placed,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? orderDate;

  int get total => items.fold(0, (sum, item) => sum + item.subtotal);

  String get formattedTotal {
    final s = total.toString();
    final withCommas = s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'UGX $withCommas';
  }
}
