import 'package:flutter/material.dart';
import 'pharmconnect_theme.dart';

/// Wireframe 8: Order Management Screen (Staff view)
/// Conforms to Flutter 3.44.3 and styled with high-fidelity color presets.
class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  // Navigation Tabs matching Wireframe 8
  String _activeTab = 'All';

  // Seed data from Wireframe 8 + extra orders
  final List<Map<String, dynamic>> _allOrders = [
    {
      'id': '#1042',
      'customerName': 'Akello J.',
      'status': 'Processing',
      'total': 18500,
      'date': 'Today, 2:45 PM',
    },
    {
      'id': '#1041',
      'customerName': 'Okello D.',
      'status': 'Pending',
      'total': 25000,
      'date': 'Today, 1:15 PM',
    },
    {
      'id': '#1039',
      'customerName': 'Namata R.',
      'status': 'Shipped',
      'total': 12000,
      'date': 'Yesterday, 4:10 PM',
    }
  ];

  // Helper method to retrieve status colors securely
  Color _getStatusColor(String status) {
    return switch (status) {
      'Pending' => PharmConnectTheme.statusPending,
      'Processing' => PharmConnectTheme.statusProcessing,
      'Shipped' => PharmConnectTheme.statusShipped,
      _ => PharmConnectTheme.textSecondary,
    };
  }

  void _updateOrderStatus(String id, String newStatus) {
    setState(() {
      final index = _allOrders.indexWhere((order) => order['id'] == id);
      if (index != -1) {
        _allOrders[index]['status'] = newStatus;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 600;

    // Filtered items
    final filteredOrders = _activeTab == 'All'
        ? _allOrders
        : _allOrders.where((order) => order['status'] == _activeTab).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildNavigationTabs(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (filteredOrders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: PharmConnectTheme.textSecondary.withValues(alpha:0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'No $_activeTab orders found',
                      style: const TextStyle(color: PharmConnectTheme.textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return Align(
              alignment: Alignment.topCenter,
              child: Container(
                //maxWidth: 720,
                padding: const EdgeInsets.all(12.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    mainAxisExtent: 140,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(filteredOrders[index]);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Horizontal scrollable categories selection bar
  Widget _buildNavigationTabs() {
    final tabs = ['All', 'Pending', 'Processing', 'Shipped'];
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: PharmConnectTheme.cardBg,
        border: Border(bottom: BorderSide(color: PharmConnectTheme.borderLight, width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final bool isSelected = _activeTab == tab;

          return Padding(
            padding: const EdgeInsets.only(right: 24),
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeTab = tab;
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? PharmConnectTheme.primaryTeal : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? PharmConnectTheme.primaryTeal : PharmConnectTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Order Card matching Wireframe 8 structures
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final String status = order['status'] as String;
    final String orderId = order['id'] as String;
    final String customer = order['customerName'] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: ID & Status Accent
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderId,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: PharmConnectTheme.primaryDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Row 2: Customer Name
            Text(
              customer,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: PharmConnectTheme.textSecondary,
              ),
            ),
            const Spacer(),

            // Row 3: Total price and status action trigger
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UGX ${(order['total'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: PharmConnectTheme.primaryDark,
                  ),
                ),
                TextButton(
                  onPressed: () => _showStatusPicker(context, orderId, status),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Update Status',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PharmConnectTheme.primaryTeal,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: PharmConnectTheme.primaryTeal),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Triggers bottom picker sheet for rapid status update (UX Feature)
  void _showStatusPicker(BuildContext context, String orderId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final statuses = ['Pending', 'Processing', 'Shipped'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Update Status for $orderId',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ...statuses.map((status) {
                final bool isSelected = status == currentStatus;
                return ListTile(
                  leading: Icon(
                    Icons.check_circle_rounded,
                    color: isSelected ? PharmConnectTheme.primaryTeal : Colors.transparent,
                  ),
                  title: Text(
                    status,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? PharmConnectTheme.primaryTeal : PharmConnectTheme.textMain,
                    ),
                  ),
                  onTap: () {
                    _updateOrderStatus(orderId, status);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order $orderId updated to $status'),
                        backgroundColor: _getStatusColor(status),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}