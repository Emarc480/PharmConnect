import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../core/theme/app_theme.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().byId(orderId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Order ${order.id}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final status in OrderStatus.values)
              _StatusStep(
                status: status,
                order: order,
                isLast: status == OrderStatus.values.last,
              ),
            const Divider(height: 32),
            const Text('Estimated Delivery', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(order.status == OrderStatus.delivered
                ? 'Delivered'
                : 'Today, 4:00 PM'),
            const SizedBox(height: 16),
            const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(order.deliveryAddress),
            ),
            const SizedBox(height: 16),
            const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('${item.drugName} × ${item.quantity}'),
                    ),
                  const Divider(),
                  Text('Total: ${order.formattedTotal}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contacting pharmacy...')),
                );
              },
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Contact Pharmacy'),
            ),
            const SizedBox(height: 12),
            if (order.status != OrderStatus.delivered)
              OutlinedButton(
                onPressed: () {
                  context.read<OrderProvider>().cancelOrder(order.id);
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Cancel Order'),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final OrderStatus status;
  final Order order;
  final bool isLast;

  const _StatusStep({required this.status, required this.order, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final currentIndex = order.status.index;
    final stepIndex = status.index;
    final isDone = stepIndex < currentIndex;
    final isCurrent = stepIndex == currentIndex;

    final color = isDone || isCurrent ? AppTheme.primaryNavy : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isDone ? AppTheme.primaryNavy : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            status.label,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isDone || isCurrent ? Theme.of(context).colorScheme.onSurface : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
