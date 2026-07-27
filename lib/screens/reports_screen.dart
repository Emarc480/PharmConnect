import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/drug_categories.dart';
import '../core/theme/app_theme.dart';
import '../providers/drug_provider.dart';
import '../providers/order_provider.dart';

enum _ReportRange { today, last7, last30, allTime }

extension on _ReportRange {
  String get label {
    switch (this) {
      case _ReportRange.today:
        return 'Today';
      case _ReportRange.last7:
        return '7 Days';
      case _ReportRange.last30:
        return '30 Days';
      case _ReportRange.allTime:
        return 'All Time';
    }
  }

  bool includes(DateTime date) {
    final now = DateTime.now();
    switch (this) {
      case _ReportRange.today:
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case _ReportRange.last7:
        return now.difference(date).inDays <= 7;
      case _ReportRange.last30:
        return now.difference(date).inDays <= 30;
      case _ReportRange.allTime:
        return true;
    }
  }
}

/// Sales & inventory analytics built entirely from data the app
/// already streams (OrderProvider, DrugProvider) — no new Firestore
/// reads required. Gives staff a Reports view rather than just a
/// dashboard number: best sellers, revenue by category, and a
/// stock-health summary, over a selectable date range.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportRange _range = _ReportRange.last7;

  String _formatUgx(num amount) {
    final s = amount.round().toString();
    final withCommas = s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return 'UGX $withCommas';
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;
    final drugProvider = context.watch<DrugProvider>();

    final inRange = orders.where((o) => _range.includes(o.orderDate)).toList();
    final totalRevenue = inRange.fold<double>(0, (sum, o) => sum + o.total);
    final orderCount = inRange.length;
    final avgOrderValue = orderCount == 0 ? 0.0 : totalRevenue / orderCount;

    // Aggregate quantity + revenue sold per drug across the range.
    final qtyByDrug = <String, int>{};
    final revenueByDrug = <String, double>{};
    final nameByDrug = <String, String>{};
    final revenueByCategory = <String, double>{};

    for (final order in inRange) {
      for (final item in order.items) {
        qtyByDrug.update(item.drugId, (v) => v + item.quantity, ifAbsent: () => item.quantity);
        revenueByDrug.update(item.drugId, (v) => v + item.subtotal, ifAbsent: () => item.subtotal);
        nameByDrug[item.drugId] = item.drugName;

        final category = drugProvider.byId(item.drugId)?.category ?? 'Uncategorized';
        revenueByCategory.update(category, (v) => v + item.subtotal, ifAbsent: () => item.subtotal);
      }
    }

    final bestSellers = qtyByDrug.keys.toList()
      ..sort((a, b) => qtyByDrug[b]!.compareTo(qtyByDrug[a]!));
    final topSellers = bestSellers.take(5).toList();

    final categoryEntries = revenueByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCategoryRevenue = categoryEntries.isEmpty ? 1.0 : categoryEntries.first.value;
    final maxSellerQty = topSellers.isEmpty ? 1 : qtyByDrug[topSellers.first]!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, AppTheme.navBarClearance),
          children: [
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _ReportRange.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final option = _ReportRange.values[i];
                  final selected = option == _range;
                  return ChoiceChip(
                    label: Text(option.label),
                    selected: selected,
                    selectedColor: AppTheme.primaryNavy,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _range = option),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Revenue',
                    value: _formatUgx(totalRevenue),
                    icon: Icons.payments_outlined,
                    color: AppTheme.inStockGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: 'Orders',
                    value: '$orderCount',
                    icon: Icons.receipt_long_outlined,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Avg. Order Value',
                    value: _formatUgx(avgOrderValue),
                    icon: Icons.trending_up,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: 'Stock Alerts',
                    value: '${drugProvider.lowStockCount + drugProvider.expiringSoonCount}',
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.lowStockOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Best Sellers', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('By units sold in this period', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
            const SizedBox(height: 12),
            if (topSellers.isEmpty)
              _EmptyNote(text: 'No sales recorded in this period yet.')
            else
              _ReportCard(
                children: [
                  for (var i = 0; i < topSellers.length; i++)
                    _BarRow(
                      label: nameByDrug[topSellers[i]] ?? 'Unknown',
                      value: qtyByDrug[topSellers[i]]!.toDouble(),
                      maxValue: maxSellerQty.toDouble(),
                      trailing: '${qtyByDrug[topSellers[i]]} sold · ${_formatUgx(revenueByDrug[topSellers[i]] ?? 0)}',
                      color: AppTheme.primaryNavy,
                      isLast: i == topSellers.length - 1,
                    ),
                ],
              ),
            const SizedBox(height: 28),
            Text('Revenue by Category', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (categoryEntries.isEmpty)
              _EmptyNote(text: 'No category revenue in this period yet.')
            else
              _ReportCard(
                children: [
                  for (var i = 0; i < categoryEntries.length; i++)
                    _BarRow(
                      label: categoryEntries[i].key,
                      icon: categoryIcon(categoryEntries[i].key),
                      value: categoryEntries[i].value,
                      maxValue: maxCategoryRevenue,
                      trailing: _formatUgx(categoryEntries[i].value),
                      color: categoryColor(categoryEntries[i].key),
                      isLast: i == categoryEntries.length - 1,
                    ),
                ],
              ),
            const SizedBox(height: 28),
            Text('Inventory Health', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _ReportCard(
              children: [
                _StatRow(
                  icon: Icons.warning_amber_rounded,
                  color: AppTheme.lowStockOrange,
                  label: 'Low stock items',
                  value: '${drugProvider.lowStockCount}',
                  isLast: false,
                ),
                _StatRow(
                  icon: Icons.block_rounded,
                  color: Colors.grey.shade700,
                  label: 'Out of stock items',
                  value: '${drugProvider.outOfStockCount}',
                  isLast: false,
                ),
                _StatRow(
                  icon: Icons.event_busy_outlined,
                  color: Colors.deepOrange,
                  label: 'Expiring within 30 days',
                  value: '${drugProvider.expiringSoonCount}',
                  isLast: false,
                ),
                _StatRow(
                  icon: Icons.dangerous_outlined,
                  color: Colors.red,
                  label: 'Already expired',
                  value: '${drugProvider.expiredCount}',
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navBarSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.navBarSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(children: children),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.trailing,
    required this.color,
    required this.isLast,
    this.icon,
  });

  final String label;
  final double value;
  final double maxValue;
  final String trailing;
  final Color color;
  final bool isLast;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              ),
              Text(trailing, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          if (!isLast) const SizedBox(height: 4),
          if (!isLast) Divider(height: 20, color: AppTheme.borderGrey),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.color, required this.label, required this.value, required this.isLast});

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
              Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: AppTheme.borderGrey),
      ],
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navBarSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
    );
  }
}
