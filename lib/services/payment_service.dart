import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentProvider { mtn, airtel }

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);

  @override
  String toString() => message;
}

/// Coursework-demo payment service.
///
/// Simulates an MTN MoMo / Airtel Money "Request to Pay" flow —
/// same UX as the real thing (a short wait while the "customer"
/// approves a prompt on their phone, then paid/failed) — without
/// calling the real telco APIs. That means no Cloud Functions, no
/// secret keys, and no Firebase Blaze plan needed to demo it.
///
/// Swap this out for the real MTN/Airtel-backed version (Cloud
/// Functions calling the sandbox APIs) if you later want the
/// integration to be genuine rather than simulated — see
/// PAYMENTS.md for that path.
class PaymentService {
  final _random = Random();
  final _orders = FirebaseFirestore.instance.collection('orders');

  Future<String> initiatePayment({
    required PaymentProvider provider,
    required String orderId,
    required String phone,
    required double amount,
  }) async {
    // Pretend we just sent the push prompt to the phone.
    await Future.delayed(const Duration(seconds: 2));

    final reference =
        '${provider == PaymentProvider.mtn ? 'MTN' : 'AIRTEL'}-DEMO-${DateTime.now().millisecondsSinceEpoch}';

    try {
      await _orders.doc(orderId).update({
        'paymentMethod': provider == PaymentProvider.mtn ? 'mtn' : 'airtel',
        'paymentStatus': 'pending',
        'paymentReference': reference,
      });
    } catch (_) {
      throw PaymentException('Could not start the payment. Please try again.');
    }

    return reference;
  }

  /// Simulates the customer approving (or occasionally declining)
  /// the prompt on their phone. Succeeds 90% of the time so a demo
  /// run is reliable, while still showing the failure path exists.
  Future<String> pollPaymentStatus({
    required PaymentProvider provider,
    required String orderId,
    Duration simulatedWait = const Duration(seconds: 3),
  }) async {
    await Future.delayed(simulatedWait);

    final status = _random.nextDouble() < 0.9 ? 'paid' : 'failed';

    try {
      await _orders.doc(orderId).update({'paymentStatus': status});
    } catch (_) {
      throw PaymentException('Could not confirm payment status.');
    }

    return status;
  }
}
