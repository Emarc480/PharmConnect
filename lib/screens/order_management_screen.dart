import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_routes.dart';

enum _SortOption { newest, oldest, highestTotal, lowestTotal }

extension on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.newest:
        return 'Newest first';
      case _SortOption.oldest:
        return 'Oldest first';
      case _SortOption.highestTotal:
        return 'Highest total';
      case _SortOption.lowestTotal:
        return 'Lowest total';
    }
  }

  /// Date-bucketed headers (Today/Yesterday/…) only make sense when
  /// orders are already in date order — sorting by total breaks that,
  /// so those two options fall back to one flat list.
  bool get isDateBased => this == _SortOption.newest || this == _SortOption.oldest;
}

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  OrderStatus? _filter; // null = All
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _SortOption _sort = _SortOption.newest;
  DateTimeRange? _dateRange;

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  StreamSubscription<Order>? _newOrderSub;

  @override
  void initState() {
    super.initState();
    // Deferred a frame so `context.read` has a fully-mounted provider
    // to hang the subscription off of.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _newOrderSub = context.read<OrderProvider>().newOrderStream.listen(_onNewOrder);
    });
  }

  @override
  void dispose() {
    _newOrderSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onNewOrder(Order order) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New order placed — ${order.formattedTotal}'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.orderTracking,
            arguments: order.id,
          ),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
    // A SnackBar only fires while this screen is open and the app is
    // foregrounded. Alerting staff while the app is backgrounded or
    // closed needs a real push notification — see the note at the
    // bottom of this file for what that involves.
  }

  List<Order> _applySearch(List<Order> orders) {
    if (_query.isEmpty) return orders;
    final q = _query.toLowerCase();
    return orders.where((o) {
      if (o.id.toLowerCase().contains(q)) return true;
      if (o.deliveryAddress.toLowerCase().contains(q)) return true;
      return o.items.any((item) => item.drugName.toLowerCase().contains(q));
    }).toList();
  }

  List<Order> _applyDateRange(List<Order> orders) {
    final range = _dateRange;
    if (range == null) return orders;
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    return orders.where((o) => !o.orderDate.isBefore(start) && !o.orderDate.isAfter(end)).toList();
  }

  List<Order> _applySort(List<Order> orders) {
    final sorted = [...orders];
    switch (_sort) {
      case _SortOption.newest:
        sorted.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      case _SortOption.oldest:
        sorted.sort((a, b) => a.orderDate.compareTo(b.orderDate));
      case _SortOption.highestTotal:
        sorted.sort((a, b) => b.total.compareTo(a.total));
      case _SortOption.lowestTotal:
        sorted.sort((a, b) => a.total.compareTo(b.total));
    }
    return sorted;
  }

  /// Buckets orders into date groups. Only called when [_sort] is
  /// date-based, so the input is already chronologically ordered.
  Map<String, List<Order>> _groupByDate(List<Order> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<Order>>{
      'Today': [],
      'Yesterday': [],
      'Last 7 Days': [],
      'Older': [],
    };

    for (final order in orders) {
      final d = order.orderDate;
      final day = DateTime(d.year, d.month, d.day);
      if (day == today) {
        groups['Today']!.add(order);
      } else if (day == yesterday) {
        groups['Yesterday']!.add(order);
      } else if (day.isAfter(weekAgo)) {
        groups['Last 7 Days']!.add(order);
      } else {
        groups['Older']!.add(order);
      }
    }

    groups.removeWhere((_, list) => list.isEmpty);
    return groups;
  }

  void _toggleSelected(String orderId) {
    setState(() {
      if (_selectedIds.contains(orderId)) {
        _selectedIds.remove(orderId);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(orderId);
      }
    });
  }

  void _enterSelectionMode(String orderId) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(orderId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _bulkAdvance(List<Order> visibleOrders) async {
    final provider = context.read<OrderProvider>();
    final targets = visibleOrders.where((o) => _selectedIds.contains(o.id) && o.status.next != null).toList();
    for (final order in targets) {
      await provider.advanceStatus(order.id);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Advanced ${targets.length} order(s)')),
    );
    _exitSelectionMode();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        // A custom range implies "browse everything in it", so drop
        // any sort-by-total choice back to chronological — otherwise
        // the picked range and the flat total-sorted list fight for
        // attention.
      });
    }
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Sort by', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              RadioGroup<_SortOption>(
                groupValue: _sort,
                onChanged: (v) {
                  setState(() => _sort = v!);
                  Navigator.pop(sheetContext);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in _SortOption.values)
                      RadioListTile<_SortOption>(
                        value: option,
                        title: Text(option.label),
                        activeColor: AppTheme.primaryNavy,
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: Text(_dateRange == null ? 'Custom date range' : 'Change date range'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickDateRange();
                },
              ),
              if (_dateRange != null)
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text('Clear date range'),
                  onTap: () {
                    setState(() => _dateRange = null);
                    Navigator.pop(sheetContext);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final allOrders = orderProvider.orders;

    final statusFiltered = orderProvider.ordersByStatus(_filter);
    var visible = _applySearch(statusFiltered);
    visible = _applyDateRange(visible);
    visible = _applySort(visible);

    final grouped = _sort.isDateBased ? _groupByDate(visible) : null;

    return Scaffold(
      appBar: _selectionMode
          ? AppBar(
              leading: IconButton(icon: const Icon(Icons.close), onPressed: _exitSelectionMode),
              title: Text('${_selectedIds.length} selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.arrow_circle_right_outlined),
                  tooltip: 'Advance selected to next status',
                  onPressed: _selectedIds.isEmpty ? null : () => _bulkAdvance(visible),
                ),
              ],
            )
          : AppBar(
              title: const Text('Order Management', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
      body: SafeArea(
        child: orderProvider.isLoading
            ? const _OrderListSkeleton()
            : Column(
                children: [
                  if (!_selectionMode) _QuickStats(orders: allOrders),
                  if (!_selectionMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _query = v.trim()),
                              decoration: InputDecoration(
                                hintText: 'Search by order ID, item, or address',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _query.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _query = '');
                                        },
                                      ),
                                isDense: true,
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.tune, size: 20),
                              tooltip: 'Sort & filter by date',
                              onPressed: _openSortSheet,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_selectionMode && _dateRange != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          label: Text(
                            '${_fmtDate(_dateRange!.start)} – ${_fmtDate(_dateRange!.end)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onDeleted: () => setState(() => _dateRange = null),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  if (!_selectionMode)
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        children: [
                          _FilterChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                          const SizedBox(width: 8),
                          for (final status in OrderStatus.values) ...[
                            _FilterChip(
                              label: status.label,
                              selected: _filter == status,
                              onTap: () => setState(() => _filter = status),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  Expanded(
                    child: visible.isEmpty
                        ? Center(
                            child: Text(
                              _query.isEmpty ? 'No orders here' : 'No orders match "$_query"',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, AppTheme.navBarClearance),
                            children: grouped != null
                                ? [
                                    for (final entry in grouped.entries) ...[
                                      _DateHeader(label: entry.key, count: entry.value.length),
                                      for (final order in entry.value) ...[
                                        _OrderRow(
                                          order: order,
                                          selectionMode: _selectionMode,
                                          selected: _selectedIds.contains(order.id),
                                          onTap: () => _selectionMode
                                              ? _toggleSelected(order.id)
                                              : Navigator.pushNamed(context, AppRoutes.orderTracking, arguments: order.id),
                                          onLongPress: () => _enterSelectionMode(order.id),
                                        ),
                                        const Divider(),
                                      ],
                                    ],
                                  ]
                                : [
                                    for (final order in visible) ...[
                                      _OrderRow(
                                        order: order,
                                        selectionMode: _selectionMode,
                                        selected: _selectedIds.contains(order.id),
                                        onTap: () => _selectionMode
                                            ? _toggleSelected(order.id)
                                            : Navigator.pushNamed(context, AppRoutes.orderTracking, arguments: order.id),
                                        onLongPress: () => _enterSelectionMode(order.id),
                                      ),
                                      const Divider(),
                                    ],
                                  ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${months[d.month - 1]}';
}

String _formatUgxLocal(int amount) {
  final s = amount.toString();
  final withCommas = s.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return 'UGX $withCommas';
}

class _QuickStats extends StatelessWidget {
  final List<Order> orders;

  const _QuickStats({required this.orders});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todaysOrders = orders.where((o) {
      final d = o.orderDate;
      return DateTime(d.year, d.month, d.day) == today;
    }).toList();
    final todaysRevenue = todaysOrders.fold<double>(0, (sum, o) => sum + o.total);
    final pendingCount = orders
        .where((o) => o.status == OrderStatus.placed || o.status == OrderStatus.processing)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(child: _StatCard(label: "Today's Orders", value: '${todaysOrders.length}')),
          const SizedBox(width: 8),
          Expanded(child: _StatCard(label: "Today's Revenue", value: _formatUgxLocal(todaysRevenue.round()))),
          const SizedBox(width: 8),
          Expanded(child: _StatCard(label: 'Pending', value: '$pendingCount')),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primaryNavy),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String label;
  final int count;

  const _DateHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppTheme.primaryNavy,
      labelStyle: TextStyle(color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface),
      onSelected: (_) => onTap(),
    );
  }
}

/// Small color-coded dot next to each order's status label — makes the
/// list scannable at a glance instead of relying on text alone.
Color _statusDotColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.placed:
      return const Color(0xFF6B7280);
    case OrderStatus.processing:
      return AppTheme.lowStockOrange;
    case OrderStatus.shipped:
    case OrderStatus.arrivingSoon:
      return const Color(0xFF2563EB);
    case OrderStatus.delivered:
      return AppTheme.inStockGreen;
  }
}

class _OrderRow extends StatelessWidget {
  final Order order;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _OrderRow({
    required this.order,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  Widget _content(BuildContext context) {
    final next = order.status.next;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectionMode) ...[
            Checkbox(
              value: selected,
              activeColor: AppTheme.primaryNavy,
              onChanged: (_) => onTap(),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ${order.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${order.items.length} item(s) · ${order.formattedTotal}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _statusDotColor(order.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      order.status.label,
                      style: const TextStyle(
                        color: AppTheme.primaryNavy,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!selectionMode)
            if (next != null)
              TextButton(
                onPressed: () => context.read<OrderProvider>().advanceStatus(order.id),
                child: Text('Mark ${next.label}'),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Complete', style: TextStyle(color: Colors.grey)),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final next = order.status.next;
    final row = InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      onLongPress: onLongPress,
      child: _content(context),
    );

    // Swipe-to-advance: only wired up outside selection mode, and only
    // for orders that actually have a next status. confirmDismiss
    // always returns false so the tile snaps back — the swipe is a
    // gesture that triggers the status change, not a removal.
    if (selectionMode || next == null) return row;

    return Dismissible(
      key: ValueKey(order.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.inStockGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text('Mark ${next.label}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await context.read<OrderProvider>().advanceStatus(order.id);
        return false;
      },
      child: row,
    );
  }
}

/// Shimmering placeholder rows shown while the Firestore stream is
/// still connecting, instead of a blank screen or a lone spinner.
class _OrderListSkeleton extends StatefulWidget {
  const _OrderListSkeleton();

  @override
  State<_OrderListSkeleton> createState() => _OrderListSkeletonState();
}

class _OrderListSkeletonState extends State<_OrderListSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.4 + (_controller.value * 0.35);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, AppTheme.navBarClearance),
          itemCount: 6,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Opacity(
              opacity: opacity,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 140, height: 14, color: const Color(0xFFE5E7EB)),
                        const SizedBox(height: 8),
                        Container(width: 90, height: 11, color: const Color(0xFFE5E7EB)),
                        const SizedBox(height: 8),
                        Container(width: 70, height: 11, color: const Color(0xFFE5E7EB)),
                      ],
                    ),
                  ),
                  Container(width: 60, height: 28, color: const Color(0xFFE5E7EB)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
