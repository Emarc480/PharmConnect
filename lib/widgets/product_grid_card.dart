import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/constants/drug_categories.dart';
import '../core/constants/countries.dart';
import '../models/drug.dart';
import 'grid_card_kit.dart';

/// Two-column catalog card, styled to match the staff-facing Inventory
/// grid card: borderless rounded photo tile with a floating status
/// badge (discount, or low/out-of-stock when there's no discount to
/// show), a frosted wishlist heart in place of the edit pencil, then
/// name, a tinted category pill, a condensed manufacturer/origin
/// line, price (with a struck-through original price when
/// discounted), and a filled "Add to Cart" pill in place of the
/// stock stepper — used on the Home tab's product grid and Offers
/// rail.
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
    final catColor = categoryColor(drug.category);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GridCardStyle.radius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(GridCardStyle.radius),
          border: GridCardStyle.hairline,
          boxShadow: GridCardStyle.shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(GridCardStyle.imageRadius),
                    ),
                    child: drug.hasImage
                        ? Image.memory(
                            base64Decode(drug.imageBase64!),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: catColor.withValues(alpha: 0.10),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(categoryIcon(drug.category), size: 30, color: catColor),
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: drug.hasDiscount
                        ? GridCardBadge(
                            label: '-${drug.discountPercent}%',
                            color: const Color(0xFFE11D48),
                            icon: Icons.local_offer_rounded,
                          )
                        : isOutOfStock
                            ? GridCardBadge(
                                label: 'Out of stock',
                                color: Colors.grey.shade700,
                                icon: Icons.block_rounded,
                              )
                            : isLowStock
                                ? const GridCardBadge(
                                    label: 'Low stock',
                                    color: Color(0xFFEA580C),
                                    icon: Icons.bolt_rounded,
                                  )
                                : const SizedBox.shrink(),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GlassIconButton(
                      icon: isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      onTap: onToggleWishlist,
                      color: isWishlisted ? const Color(0xFFE11D48) : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drug.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.1,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  CategoryPill(label: drug.category, icon: categoryIcon(drug.category), color: catColor),
                  if (drug.hasManufacturer) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Manufactured by:',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                    ),
                    Text(
                      drug.manufacturerName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                  ],
                  if (countryName != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(countryFlagEmoji(drug.countryOfOrigin), style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            countryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        drug.formattedPrice,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryNavy,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (drug.hasDiscount) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            drug.formattedOriginalPrice,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: isOutOfStock ? null : onAddToCart,
                      icon: Icon(
                        isOutOfStock ? Icons.remove_shopping_cart_rounded : Icons.add_shopping_cart_rounded,
                        size: 15,
                      ),
                      label: Text(
                        isOutOfStock ? 'Out of Stock' : 'Add to Cart',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        disabledBackgroundColor: Colors.grey.shade200,
                        disabledForegroundColor: Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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