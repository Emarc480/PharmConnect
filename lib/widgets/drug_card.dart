import 'package:flutter/material.dart';
import '../models/drug.dart';
import '../core/theme/app_theme.dart';

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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.medication, color: Colors.grey),
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