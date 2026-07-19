import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/drug.dart';

/// Two-column catalog card: stock pill + wishlist heart over an image
/// placeholder, name, price (with a struck-through original price
/// when the drug is discounted), and a full-width "Add to Cart"
/// button — used on the Home tab's product grid and Offers rail.
class ProductGridCard extends StatelessWidget {
  final Drug drug;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onToggleWishlist;
  final VoidCallback onAddToCart;

  const ProductGridCard({
    super.key,
    required this.drug,
    required this.isWishlisted,
    required this.onTap,
    required this.onToggleWishlist,
    required this.onAddToCart,
  });

  Color get _stockColor {
    switch (drug.stockStatus) {
      case StockStatus.inStock:
        return AppTheme.inStockGreen;
      case StockStatus.lowStock:
        return AppTheme.lowStockOrange;
      case StockStatus.outOfStock:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = drug.stockStatus == StockStatus.outOfStock;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.35,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Center(
                      child: Icon(Icons.medication_outlined, size: 40, color: Colors.grey.shade400),
                    ),
                  ),
                  if (drug.hasDiscount)
                    Positioned(
                      left: 0,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(6)),
                        ),
                        child: Text(
                          '${drug.discountPercent}% Off',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(color: _stockColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            drug.stockLabel,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _stockColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: InkWell(
                      onTap: onToggleWishlist,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isWishlisted ? Colors.redAccent : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drug.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        drug.formattedPrice,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                      ),
                      if (drug.hasDiscount) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            drug.formattedOriginalPrice,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: OutlinedButton(
                      onPressed: isOutOfStock ? null : onAddToCart,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryNavy,
                        side: BorderSide(color: isOutOfStock ? Colors.grey.shade300 : AppTheme.primaryNavy),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        isOutOfStock ? 'Out of Stock' : 'Add to Cart',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}