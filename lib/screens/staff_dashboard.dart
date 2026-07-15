import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_routes.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/refill_provider.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  String _formatUgx(int amount) {
    final s = amount.toString();
    final withCommas = s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'UGX $withCommas';
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;
    final inventory = context.watch<InventoryProvider>();
    final refills = context.watch<RefillProvider>();

    final newOrders = orders.where((o) => o.status == OrderStatus.placed).length;
    final todaysSales = orders
        .where((o) => o.orderDate.day == DateTime.now().day)
        .fold(0, (sum, o) => sum + o.total);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "PharmConnect Staff",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats grid — 2x2
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: "New Orders",
                    value: "$newOrders",
                    valueColor: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    label: "Low Stock",
                    value: "${inventory.lowStockCount}",
                    valueColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: "Today's Sales",
                    value: _formatUgx(todaysSales),
                    valueColor: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    label: "Pending Refills",
                    value: "${refills.pendingCount}",
                    valueColor: Colors.black87,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.refillManagement),
                  ),
                ),
              ],
            ),
            const Spacer(),

            // View Orders button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.orders);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B2A4A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("View Orders"),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF1B2A4A),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              // already on Dashboard
              break;
            case 1:
              Navigator.pushNamed(context, AppRoutes.inventory);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.orders);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.profile);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: "Inventory",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}