import 'drug.dart';

/// Five steps to match the "Track Order" screen design: Order
/// Confirmed → Being Prepared → On the Way → Arriving Soon →
/// Delivered Safely.
enum OrderStatus { placed, processing, shipped, arrivingSoon, delivered }

extension OrderStatusLabel on OrderStatus {
  /// Short label — used in filter chips, staff lists, etc.
  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.arrivingSoon:
        return 'Arriving Soon';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  /// Timeline step label — matches the wording on the Track Order
  /// screen's status list exactly.
  String get timelineLabel {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Confirmed';
      case OrderStatus.processing:
        return 'Being Prepared';
      case OrderStatus.shipped:
        return 'On the Way';
      case OrderStatus.arrivingSoon:
        return 'Arriving Soon';
      case OrderStatus.delivered:
        return 'Delivered Safely';
    }
  }

  OrderStatus? get next {
    switch (this) {
      case OrderStatus.placed:
        return OrderStatus.processing;
      case OrderStatus.processing:
        return OrderStatus.shipped;
      case OrderStatus.shipped:
        return OrderStatus.arrivingSoon;
      case OrderStatus.arrivingSoon:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
        return null;
    }
  }

  /// One step back — powers the "revert" action for staff who advance
  /// an order by mistake (e.g. marked Shipped before it actually went
  /// out). Null for [placed], since there's nothing before it.
  OrderStatus? get previous {
    switch (this) {
      case OrderStatus.placed:
        return null;
      case OrderStatus.processing:
        return OrderStatus.placed;
      case OrderStatus.shipped:
        return OrderStatus.processing;
      case OrderStatus.arrivingSoon:
        return OrderStatus.shipped;
      case OrderStatus.delivered:
        return OrderStatus.arrivingSoon;
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

/// A small fixed pool of demo riders. A real production app would
/// pull this from a "riders" collection tied to a rider role/account;
/// for this project's scope, a rider is deterministically assigned
/// (by order id) the moment an order goes out for delivery, which is
/// enough to power the "Your Rider" card on the tracking screen.
class DemoRider {
  final String name;
  final double rating;
  const DemoRider(this.name, this.rating);

  static const List<DemoRider> pool = [
    DemoRider('Brian', 4.8),
    DemoRider('Grace', 4.9),
    DemoRider('Kato', 4.7),
    DemoRider('Sarah', 4.9),
    DemoRider('Moses', 4.6),
  ];

  static DemoRider forOrderId(String orderId) {
    final index = orderId.hashCode.abs() % pool.length;
    return pool[index];
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

  /// When each status was first reached — powers the timestamp shown
  /// next to every step on the Track Order timeline. Keyed by
  /// [OrderStatus.name]. Always contains at least 'placed'.
  final Map<String, DateTime> statusTimestamps;

  /// Assigned once the order heads out for delivery (see
  /// OrderProvider.advanceStatus). Null before then, and always null
  /// for orders that only ever reach 'processing', etc.
  final String? riderName;
  final double? riderRating;

  /// Set by the Cloud Functions payment backend once checkout starts —
  /// never written directly by the client. 'unpaid' until a payment
  /// attempt is initiated, then 'pending' -> 'paid' | 'failed'.
  final String paymentStatus;

  /// 'mtn' or 'airtel' once a payment attempt has been made; null
  /// before then (e.g. order just created, or cash on delivery).
  final String? paymentMethod;

  /// The MTN referenceId / Airtel transactionId for the most recent
  /// payment attempt on this order — used to poll status.
  final String? paymentReference;

  Order({
    required this.id,
    required this.customerId,
    required this.items,
    required this.orderDate,
    required this.deliveryAddress,
    this.status = OrderStatus.placed,
    DateTime? lastUpdated,
    Map<String, DateTime>? statusTimestamps,
    this.riderName,
    this.riderRating,
    this.paymentStatus = 'unpaid',
    this.paymentMethod,
    this.paymentReference,
  })  : lastUpdated = lastUpdated ?? orderDate,
        statusTimestamps = statusTimestamps ?? {OrderStatus.placed.name: orderDate};

  double get total => items.fold(0.0, (sum, item) => sum + item.subtotal);

  String get formattedTotal => _formatUgx(total.round());

  /// Timestamp for [status] if that step has been reached, else null —
  /// used to grey out/hide "Pending" steps on the timeline.
  DateTime? timestampFor(OrderStatus s) => statusTimestamps[s.name];

  /// 0.0 (just placed) to 1.0 (delivered) — drives how far along the
  /// route the rider marker sits on the decorative tracking map.
  double get progress => status.index / (OrderStatus.values.length - 1);

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    final itemsRaw = (map['items'] as List<dynamic>?) ?? const [];
    final orderDate = DateTime.fromMillisecondsSinceEpoch(
      (map['orderDateMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
    final rawTimestamps = map['statusTimestampsMs'] as Map<String, dynamic>?;
    return Order(
      id: id,
      customerId: (map['customerId'] as String?) ?? '',
      items: itemsRaw
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      orderDate: orderDate,
      deliveryAddress: (map['deliveryAddress'] as String?) ?? '',
      status: OrderStatusLabel.fromName((map['status'] as String?) ?? 'placed'),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        (map['lastUpdatedMs'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      statusTimestamps: rawTimestamps == null
          ? {OrderStatus.placed.name: orderDate}
          : rawTimestamps.map(
              (k, v) => MapEntry(k, DateTime.fromMillisecondsSinceEpoch((v as num).toInt())),
            ),
      riderName: map['riderName'] as String?,
      riderRating: (map['riderRating'] as num?)?.toDouble(),
      paymentStatus: (map['paymentStatus'] as String?) ?? 'unpaid',
      paymentMethod: map['paymentMethod'] as String?,
      paymentReference: map['paymentReference'] as String?,
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
      'statusTimestampsMs': statusTimestamps.map((k, v) => MapEntry(k, v.millisecondsSinceEpoch)),
      if (riderName != null) 'riderName': riderName,
      if (riderRating != null) 'riderRating': riderRating,
      'paymentStatus': paymentStatus,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentReference != null) 'paymentReference': paymentReference,
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
