import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drug.dart';
import '../providers/cart_provider.dart';
import '../providers/refill_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_routes.dart';
import '../core/constants/countries.dart';

class DrugDetailScreen extends StatefulWidget {
  final Drug drug;

  const DrugDetailScreen({super.key, required this.drug});

  @override
  State<DrugDetailScreen> createState() => _DrugDetailScreenState();
}

class _DrugDetailScreenState extends State<DrugDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final drug = widget.drug;
    final maxQty = drug.unitsAvailable;
    final outOfStock = drug.stockStatus == StockStatus.outOfStock;

    return Scaffold(
      appBar: AppBar(title: const Text('Drug Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: drug.hasImage
                  ? Image.memory(
                      base64Decode(drug.imageBase64!),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 160,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(Icons.medication, size: 56, color: Colors.grey),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    drug.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  drug.formattedPrice,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  drug.category,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (countryNameForCode(drug.countryOfOrigin) != null) ...[
                  Text('  •  ', style: TextStyle(color: Colors.grey.shade400)),
                  Text(countryFlagEmoji(drug.countryOfOrigin), style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    'Made in ${countryNameForCode(drug.countryOfOrigin)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              drug.stockLabel,
              style: TextStyle(
                color: drug.stockStatus == StockStatus.inStock
                    ? AppTheme.inStockGreen
                    : drug.stockStatus == StockStatus.lowStock
                        ? AppTheme.lowStockOrange
                        : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(height: 32),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Used for relief of mild to moderate symptoms. Follow dosage '
                'instructions on the packaging or as advised by your pharmacist.',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  onTap: outOfStock || _quantity <= 1
                      ? null
                      : () => setState(() => _quantity--),
                ),
                Container(
                  width: 56,
                  alignment: Alignment.center,
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                _QtyButton(
                  icon: Icons.add,
                  onTap: outOfStock || _quantity >= maxQty
                      ? null
                      : () => setState(() => _quantity++),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: outOfStock
                  ? null
                  : () {
                      context.read<CartProvider>().addToCart(drug, quantity: _quantity);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added $_quantity × ${drug.name} to cart')),
                      );
                      Navigator.pushNamed(context, AppRoutes.cart);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(outOfStock ? 'Out of Stock' : 'Add to Cart'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                context.read<RefillProvider>().submitRequest(drugName: drug.name);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Refill request sent for ${drug.name}')),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Request Refill'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderGrey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: onTap == null ? Colors.grey.shade300 : Colors.black87),
      ),
    );
  }
}