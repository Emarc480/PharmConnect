import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_routes.dart';

class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: SafeArea(
        child: orders.isEmpty
            ? const Center(child: Text('You have no orders yet'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, i) {
                  final order = orders[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Order ${order.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${order.items.length} item(s) · ${order.formattedTotal}'),
                    trailing: Text(
                      order.status.label,
                      style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.orderTracking,
                      arguments: order.id,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
