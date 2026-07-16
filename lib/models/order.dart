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

  static OrderStatus fromName(String name) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => OrderStatus.placed,
    );
  }
}

/// A line item on an order. Stores a price/name *snapshot* at the time
/// of purchase (drugId as the FK, per the ERD's ORDER_ITEM entity) so
/// order history stays accurate even if the drug's live price changes
/// later — matching FR12 (permanent transaction history).
class OrderItem {
  final String drugId;
  final String drugName;
  final double unitPrice;
  final int quantity;

  OrderItem({
    required this.drugId,
    required this.drugName,
    required this.unitPrice,
    required this.quantity,
  });

  factory OrderItem.fromDrug(Drug drug, int quantity) {
    return OrderItem(
      drugId: drug.id,
      drugName: drug.name,
      unitPrice: drug.price,
      quantity: quantity,
    );
  }

  double get subtotal => unitPrice * quantity;

  String get formattedUnitPrice => _formatUgx(unitPrice.round());

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      drugId: (map['drugId'] as String?) ?? '',
      drugName: (map['drugName'] as String?) ?? '',
      unitPrice: ((map['unitPrice'] as num?) ?? 0).toDouble(),
      quantity: ((map['quantity'] as num?) ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'drugId': drugId,
      'drugName': drugName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}

class Order {
  final String id;
  final String customerId;
  final List<OrderItem> items;
  final DateTime orderDate;
  final String deliveryAddress;
  OrderStatus status;
  DateTime lastUpdated;

  Order({
    required this.id,
    required this.customerId,
    required this.items,
    required this.orderDate,
    required this.deliveryAddress,
    this.status = OrderStatus.placed,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? orderDate;

  double get total => items.fold(0.0, (sum, item) => sum + item.subtotal);

  String get formattedTotal => _formatUgx(total.round());

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    final itemsRaw = (map['items'] as List<dynamic>?) ?? const [];
    return Order(
      id: id,
      customerId: (map['customerId'] as String?) ?? '',
      items: itemsRaw
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      orderDate: DateTime.fromMillisecondsSinceEpoch(
        (map['orderDateMs'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      deliveryAddress: (map['deliveryAddress'] as String?) ?? '',
      status: OrderStatusLabel.fromName((map['status'] as String?) ?? 'placed'),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        (map['lastUpdatedMs'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'items': items.map((i) => i.toMap()).toList(),
      'orderDateMs': orderDate.millisecondsSinceEpoch,
      'deliveryAddress': deliveryAddress,
      'status': status.name,
      'lastUpdatedMs': lastUpdated.millisecondsSinceEpoch,
      'total': total,
    };
  }
}

String _formatUgx(int amount) {
  final s = amount.toString();
  final withCommas = s.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return 'UGX $withCommas';
}
