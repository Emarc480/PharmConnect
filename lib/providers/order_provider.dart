import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/order.dart';

/// Firestore-backed order history. `orders` (all orders, newest first)
/// is what staff screens use; `myOrders` filters that same cached list
/// down to the signed-in customer's own orders (FR6, FR12).
///
/// Security rules only let a customer read their own `orders` docs, so
/// the underlying query must be scoped server-side with a `.where()`
/// for non-staff users — an unfiltered `.orderBy()` alone would be
/// rejected by Firestore for anyone who isn't staff. [updateAuth] is
/// called from a ChangeNotifierProxyProvider in main.dart whenever
/// AuthProvider's uid/role changes, and restarts the stream with the
/// right query.
class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<Order> _orders = [];
  bool _isLoading = true;
  String? _uid;
  bool _isStaff = false;

  bool get isLoading => _isLoading;

  List<Order> get orders => List.unmodifiable(_orders);

  List<Order> get myOrders {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];
    return _orders.where((o) => o.customerId == uid).toList();
  }

  /// Restarts the Firestore listener with a query matching the current
  /// user's role. Call this whenever auth state (uid or isStaff)
  /// changes; a no-op if nothing actually changed.
  void updateAuth({required String? uid, required bool isStaff}) {
    if (_uid == uid && _isStaff == isStaff) return;
    _uid = uid;
    _isStaff = isStaff;
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    if (_uid == null) {
      _orders = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    final Query<Map<String, dynamic>> query = _isStaff
        ? _db.collection('orders').orderBy('orderDateMs', descending: true)
        : _db
            .collection('orders')
            .where('customerId', isEqualTo: _uid)
            .orderBy('orderDateMs', descending: true);

    _sub = query.snapshots().listen(_onSnapshot, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  List<Order> ordersByStatus(OrderStatus? status) {
    if (status == null) return orders;
    return orders.where((o) => o.status == status).toList();
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _orders = snapshot.docs.map((d) => Order.fromMap(d.id, d.data())).toList();
    _isLoading = false;
    notifyListeners();
  }

  /// Places the order AND decrements stock on the shared `drugs`
  /// collection in one transaction, so units-available updates for
  /// every customer immediately — the concrete payoff of unifying the
  /// Drug/Medicine models.
  Future<Order> placeOrder({
    required List<OrderItem> items,
    required String deliveryAddress,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Cannot place an order while signed out.');
    }

    final orderRef = _db.collection('orders').doc();
    final now = DateTime.now();
    final order = Order(
      id: orderRef.id,
      customerId: uid,
      items: items,
      orderDate: now,
      deliveryAddress: deliveryAddress,
    );

    await _db.runTransaction((tx) async {
      final drugRefs = {
        for (final item in items)
          item.drugId: _db.collection('drugs').doc(item.drugId),
      };
      final drugSnaps = {
        for (final entry in drugRefs.entries)
          entry.key: await tx.get(entry.value),
      };

      for (final item in items) {
        final snap = drugSnaps[item.drugId];
        if (snap == null || !snap.exists) continue;
        final currentStock = ((snap.data()?['stockQuantity'] as num?) ?? 0)
            .toInt();
        final updatedStock = (currentStock - item.quantity).clamp(0, 999999);
        tx.update(drugRefs[item.drugId]!, {'stockQuantity': updatedStock});
      }

      tx.set(orderRef, order.toMap());
    });

    return order;
  }

  Future<void> advanceStatus(String orderId) async {
    final order = byId(orderId);
    if (order == null) return;
    final next = order.status.next;
    if (next == null) return;
    final now = DateTime.now();
    final update = <String, dynamic>{
      'status': next.name,
      'lastUpdatedMs': now.millisecondsSinceEpoch,
      'statusTimestampsMs': {
        ...order.statusTimestamps.map((k, v) => MapEntry(k, v.millisecondsSinceEpoch)),
        next.name: now.millisecondsSinceEpoch,
      },
    };
    // Assign a rider the moment the order heads out for delivery, if
    // one hasn't been assigned already — powers the "Your Rider" card.
    if (order.riderName == null && next.index >= OrderStatus.shipped.index) {
      final rider = DemoRider.forOrderId(order.id);
      update['riderName'] = rider.name;
      update['riderRating'] = rider.rating;
    }
    await _db.collection('orders').doc(orderId).update(update);
  }

  Future<void> cancelOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).delete();
  }

  Order? byId(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}