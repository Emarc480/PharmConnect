import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/constants/drug_categories.dart';
import '../core/constants/countries.dart';
import '../models/drug.dart';

/// Two-column catalog card, styled to match the staff-facing Inventory
/// grid card: rounded photo tile with a top-left status badge
/// (discount, or low/out-of-stock when there's no discount to show),
/// a wishlist heart in place of the edit pencil, then name, a
/// category icon+label row, a country-of-origin flag row, price (with
/// a struck-through original price when discounted), and a
/// full-width "Add to Cart" button in place of the stock stepper —
/// used on the Home tab's product grid and Offers rail.
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

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = drug.stockStatus == StockStatus.outOfStock;
    final isLowStock = drug.isLowStock && !isOutOfStock;
    final countryName = countryNameForCode(drug.countryOfOrigin);

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
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: drug.hasImage
                        ? Image.memory(
                            base64Decode(drug.imageBase64!),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: categoryColor(drug.category).withValues(alpha: 0.1),
                            child: Center(
                              child: Icon(categoryIcon(drug.category), size: 40, color: categoryColor(drug.category)),
                            ),
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
                    )
                  else if (isOutOfStock || isLowStock)
                    Positioned(
                      left: 0,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? Colors.grey.shade600 : Colors.orange.shade700,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                        ),
                        child: Text(
                          isOutOfStock ? 'Out of Stock' : 'Low Stock',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(categoryIcon(drug.category), size: 12, color: categoryColor(drug.category)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          drug.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  if (drug.hasManufacturer) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Manufactured by:',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                    ),
                    Text(
                      drug.manufacturerName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ],
                  if (countryName != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(countryFlagEmoji(drug.countryOfOrigin), style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            countryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ],
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