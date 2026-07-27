import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/drug.dart';
import '../models/stock_movement.dart';
import '../providers/auth_provider.dart';
import '../providers/drug_provider.dart';
import '../providers/stock_movement_provider.dart';

/// The stock audit log (feature: stock movement history). Shows every
/// change to every drug's stockQuantity — restocks, quick +/- taps,
/// form edits, damage/expiry write-offs, and customer sales — newest
/// first, with who did it and when. Also the entry point for manually
/// logging a damage/loss or expired write-off via the FAB.
class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  StockMovementReason? _filter;

  @override
  Widget build(BuildContext context) {
    final movementProvider = context.watch<StockMovementProvider>();
    final movements = _filter == null
        ? movementProvider.movements
        : movementProvider.movements.where((m) => m.reason == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Stock History', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdjustmentSheet(context),
        icon: const Icon(Icons.playlist_add_outlined),
        label: const Text('Log Adjustment'),
        backgroundColor: AppTheme.primaryNavy,
      ),
      body: SafeArea(
        child: movementProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      children: [
                        _FilterChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                        const SizedBox(width: 8),
                        for (final reason in StockMovementReason.values) ...[
                          _FilterChip(
                            label: reason.label,
                            selected: _filter == reason,
                            onTap: () => setState(() => _filter = reason),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: movements.isEmpty
                        ? Center(
                            child: Text('No stock movements yet', style: TextStyle(color: Colors.grey.shade500)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: movements.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, i) => _MovementTile(movement: movements[i]),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showAdjustmentSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AdjustmentForm(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppTheme.primaryNavy,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});

  final StockMovement movement;

  Color get _color {
    if (movement.reason == StockMovementReason.restock) return AppTheme.inStockGreen;
    if (movement.reason == StockMovementReason.sale) return AppTheme.primaryNavy;
    if (movement.reason == StockMovementReason.damage || movement.reason == StockMovementReason.expired) {
      return Colors.red;
    }
    return movement.isAddition ? AppTheme.inStockGreen : AppTheme.lowStockOrange;
  }

  String _relativeTime() {
    final diff = DateTime.now().difference(movement.timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${movement.timestamp.day}/${movement.timestamp.month}/${movement.timestamp.year}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navBarSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(movement.reason.icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        movement.drugName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      movement.formattedDelta,
                      style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${movement.reason.label} · ${movement.staffName}',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
                if (movement.supplierName != null && movement.supplierName!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Supplier: ${movement.supplierName}',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                  ),
                if (movement.note != null && movement.note!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      movement.note!,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Now ${movement.resultingStock} units · ${_relativeTime()}',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for manually logging a stock adjustment that isn't a
/// restock or a customer sale — mainly damage/loss and expired
/// write-offs, plus a general correction option.
class _AdjustmentForm extends StatefulWidget {
  const _AdjustmentForm();

  @override
  State<_AdjustmentForm> createState() => _AdjustmentFormState();
}

class _AdjustmentFormState extends State<_AdjustmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();

  Drug? _selectedDrug;
  StockMovementReason _reason = StockMovementReason.damage;
  bool _isSaving = false;
  String _query = '';

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final drugs = context.watch<DrugProvider>().allDrugs
        .where((d) => d.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Log Adjustment', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Record damage, loss, or an expired write-off — separate from a normal edit, so it stays in the audit trail.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  labelText: 'Search drug',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedDrug == null)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.borderGrey), borderRadius: BorderRadius.circular(10)),
                  child: drugs.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('No drugs found'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: drugs.length,
                          itemBuilder: (context, i) {
                            final d = drugs[i];
                            return ListTile(
                              dense: true,
                              title: Text(d.name),
                              subtitle: Text('${d.stockQuantity} units in stock'),
                              onTap: () => setState(() {
                                _selectedDrug = d;
                                _searchController.text = d.name;
                                _query = '';
                              }),
                            );
                          },
                        ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.primaryNavy.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedDrug!.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('${_selectedDrug!.stockQuantity} units in stock', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _selectedDrug = null;
                          _searchController.clear();
                        }),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final reason in [StockMovementReason.damage, StockMovementReason.expired, StockMovementReason.correction])
                    ChoiceChip(
                      label: Text(reason.label),
                      selected: _reason == reason,
                      selectedColor: AppTheme.primaryNavy,
                      labelStyle: TextStyle(
                        color: _reason == reason ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _reason = reason),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Units to remove from stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid quantity';
                  if (_selectedDrug != null && n > _selectedDrug!.stockQuantity) return 'Exceeds current stock';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Log adjustment'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedDrug == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a drug first')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    final drugProvider = context.read<DrugProvider>();
    final movementProvider = context.read<StockMovementProvider>();
    final user = context.read<AuthProvider>().currentUser;
    final drug = _selectedDrug!;
    final quantity = int.parse(_quantityController.text);

    try {
      final resultingStock = await drugProvider.adjustStock(drug.id, -quantity);
      await movementProvider.logMovement(
        drugId: drug.id,
        drugName: drug.name,
        delta: -quantity,
        resultingStock: resultingStock,
        reason: _reason,
        staffId: user?.uid ?? '',
        staffName: user?.name.isNotEmpty == true ? user!.name : 'Staff',
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      navigator.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not log this adjustment. Please try again.')),
        );
      }
    }
  }
}
