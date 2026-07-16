import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/order.dart';

/// Firestore-backed order history. `orders` (all orders, newest first)
/// is what staff screens use; `myOrders` filters that same cached list
/// down to the signed-in customer's own orders (FR6, FR12).
class OrderProvider extends ChangeNotifier {
  OrderProvider() {
    _sub = _db
        .collection('orders')
        .orderBy('orderDateMs', descending: true)
        .snapshots()
        .listen(_onSnapshot, onError: (_) {});
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _sub;

  List<Order> _orders = [];
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  List<Order> get orders => List.unmodifiable(_orders);

  List<Order> get myOrders {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];
    return _orders.where((o) => o.customerId == uid).toList();
  }

  List<Order> ordersByStatus(OrderStatus? status) {
    if (status == null) return orders;
    return orders.where((o) => o.status == status).toList();
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _orders =
        snapshot.docs.map((d) => Order.fromMap(d.id, d.data())).toList();
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
        for (final item in items) item.drugId: _db.collection('drugs').doc(item.drugId),
      };
      final drugSnaps = {
        for (final entry in drugRefs.entries) entry.key: await tx.get(entry.value),
      };

      for (final item in items) {
        final snap = drugSnaps[item.drugId];
        if (snap == null || !snap.exists) continue;
        final currentStock = ((snap.data()?['stockQuantity'] as num?) ?? 0).toInt();
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
    await _db.collection('orders').doc(orderId).update({
      'status': next.name,
      'lastUpdatedMs': DateTime.now().millisecondsSinceEpoch,
    });
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
    _sub.cancel();
    super.dispose();
  }
}
