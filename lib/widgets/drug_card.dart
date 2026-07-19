import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/drug.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/drug_categories.dart';

class DrugCard extends StatelessWidget {
  final Drug drug;
  final VoidCallback? onTap;

  const DrugCard({super.key, required this.drug, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = drug.stockStatus == StockStatus.inStock
        ? AppTheme.inStockGreen
        : drug.stockStatus == StockStatus.lowStock
            ? AppTheme.lowStockOrange
            : Colors.grey;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderGrey)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: drug.hasImage
                  ? Image.memory(base64Decode(drug.imageBase64!), width: 48, height: 48, fit: BoxFit.cover)
                  : Container(
                      width: 48,
                      height: 48,
                      color: categoryColor(drug.category).withValues(alpha: 0.1),
                      child: Icon(categoryIcon(drug.category), color: categoryColor(drug.category)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(drug.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    drug.formattedPrice,
                    style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w600),
                  ),
                  Text(drug.stockLabel, style: TextStyle(color: statusColor, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}