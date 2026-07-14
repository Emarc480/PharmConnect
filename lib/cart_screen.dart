import 'package:flutter/material.dart';
import 'pharmconnect_theme.dart';

/// Wireframe 4: Cart - Order Summary Screen
/// Conforms to Flutter 3.44.3 and optimized for DevTools 2.57.0 profiling.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Hardcoded initial items from wireframe 4
  final List<Map<String, dynamic>> _cartItems = [
    {'id': 'p1', 'name': 'Panadol 500mg', 'unitPrice': 5000, 'quantity': 2},
    {'id': 'p2', 'name': 'Vitamin C 1000mg', 'unitPrice': 8500, 'quantity': 1},
  ];

  final String _deliveryAddress = 'Plot 45, Kampala Road, Sector 3';

  // Computed properties using modern Dart pattern matching and structures
  int get subtotal => _cartItems.fold(0, (sum, item) {
    final qty = item['quantity'] as int;
    final price = item['unitPrice'] as int;
    return sum + (price * qty);
  });

  void _updateQuantity(String id, int delta) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        final currentQty = _cartItems[index]['quantity'] as int;
        final nextQty = currentQty + delta;
        if (nextQty > 0) {
          _cartItems[index]['quantity'] = nextQty;
        } else {
          _cartItems.removeAt(index);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Media query and responsive constraints
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Back to Drug Details',
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Navigation or fallback actions
            },
          ),
        ),
        title: const Text('Your Cart'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Main responsive content wrapper
            return Align(
              alignment: Alignment.topCenter,
              child: Container(
                //maxWidth:
                  //  640, // Keeps card centered and proportional on tablets
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: isWide
                          ? _buildTwoColumnLayout()
                          : _buildSingleColumnLayout(),
                    ),
                    const SizedBox(height: 16),
                    _buildPlaceOrderButton(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Responsive Two-Column Layout for wider tablet profiles
  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildSectionTitle('Selected Medications'),
              ..._cartItems.map(_buildCartItemCard),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Summary & Delivery'),
              _buildSummaryCard(),
              const SizedBox(height: 12),
              _buildAddressCard(),
            ],
          ),
        ),
      ],
    );
  }

  /// Compact Single-Column Layout for standard mobile dimensions
  Widget _buildSingleColumnLayout() {
    return ListView(
      children: [
        ..._cartItems.map(_buildCartItemCard),
        const SizedBox(height: 16),
        _buildSummaryCard(),
        const SizedBox(height: 12),
        _buildAddressCard(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: PharmConnectTheme.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Individual medication item rows matching wireframe 4 styles
  Widget _buildCartItemCard(Map<String, dynamic> item) {
    final int itemTotal =
        (item['unitPrice'] as int) * (item['quantity'] as int);
    return Card(
      key: ValueKey(item['id']),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Row(
          children: [
            // Medicine Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: PharmConnectTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'x${item['quantity']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: PharmConnectTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(UGX ${item['unitPrice']}/unit)',
                        style: TextStyle(
                          fontSize: 12,
                          color: PharmConnectTheme.textSecondary.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quantity Adjuster Controls (UX Addition)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () => _updateQuantity(item['id'] as String, -1),
                  color: PharmConnectTheme.textSecondary,
                ),
                Text(
                  '${item['quantity']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () => _updateQuantity(item['id'] as String, 1),
                  color: PharmConnectTheme.primaryTeal,
                ),
              ],
            ),

            const SizedBox(width: 8),
            // Subtotal Price
            Text(
              'UGX ${itemTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: PharmConnectTheme.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card containing Totals summary matching wireframe
  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 14,
                    color: PharmConnectTheme.textSecondary,
                  ),
                ),
                Text(
                  'UGX ${subtotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Divider(color: PharmConnectTheme.borderLight, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: PharmConnectTheme.primaryDark,
                  ),
                ),
                Text(
                  'UGX ${subtotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: PharmConnectTheme.primaryTeal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Card containing the delivery address
  Widget _buildAddressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: PharmConnectTheme.primaryTeal,
                ),
                SizedBox(width: 8),
                Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PharmConnectTheme.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _deliveryAddress,
              style: const TextStyle(
                fontSize: 14,
                color: PharmConnectTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return Semantics(
      button: true,
      label: 'Place PharmConnect Order',
      child: ElevatedButton(
        onPressed: _cartItems.isEmpty
            ? null
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order Placed Successfully!'),
                    backgroundColor: PharmConnectTheme.primaryTeal,
                  ),
                );
              },
        child: const Text('Place Order'),
      ),
    );
  }
}
