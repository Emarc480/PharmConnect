import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';

/// "Track Order" screen — mirrors the map + rider + status-timeline
/// layout from the PharmConnecT promo design. The map is a lightweight
/// decorative illustration (no Maps API/key needed) whose rider-marker
/// position is driven by the order's real status, not actual GPS.
class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  /// Placeholder ETA window (no real distance/logistics calculation
  /// behind this yet — there's no rider-location or route-time data
  /// source in the project). Swap this out once real delivery-time
  /// estimation exists; until then it's a fixed, clearly-named window
  /// rather than a number buried inline.
  static const Duration _etaWindowStart = Duration(minutes: 45);
  static const Duration _etaWindowEnd = Duration(minutes: 90);

  String _headlineFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Confirmed';
      case OrderStatus.processing:
        return 'Being Prepared';
      case OrderStatus.shipped:
        return 'Out for Delivery';
      case OrderStatus.arrivingSoon:
        return 'Arriving Soon';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  String _estimatedWindow(Order order) {
    if (order.status == OrderStatus.delivered) {
      final t = order.timestampFor(OrderStatus.delivered) ?? order.lastUpdated;
      return 'Delivered ${_dayLabel(t)}, ${_timeLabel(t)}';
    }
    final start = order.orderDate.add(_etaWindowStart);
    final end = order.orderDate.add(_etaWindowEnd);
    return '${_dayLabel(start)}, ${_timeLabel(start)} – ${_timeLabel(end)}';
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
    return isToday ? 'Today' : '${d.day}/${d.month}';
  }

  String _timeLabel(DateTime t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().byId(orderId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final hasRider = order.riderName != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            _TrackOrderHeader(
              onSupportTap: () => Navigator.pushNamed(context, AppRoutes.askPharmacist),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _StatusBanner(
                    orderId: order.id,
                    headline: _headlineFor(order.status),
                    isDelivered: order.status == OrderStatus.delivered,
                  ),
                  const SizedBox(height: 14),
                  Text('Estimated Delivery', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                  const SizedBox(height: 2),
                  Text(
                    _estimatedWindow(order),
                    style: const TextStyle(
                      color: AppTheme.primaryNavy,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TrackingMap(progress: order.progress, isDelivered: order.status == OrderStatus.delivered),
                  if (hasRider) ...[
                    const SizedBox(height: 14),
                    _RiderCard(name: order.riderName!, rating: order.riderRating ?? 4.8),
                  ],
                  const SizedBox(height: 22),
                  const Text('Order Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        for (final status in OrderStatus.values)
                          _TimelineStep(
                            status: status,
                            order: order,
                            isLast: status == OrderStatus.values.last,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(order.deliveryAddress),
                  ),
                  const SizedBox(height: 16),
                  const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final item in order.items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('${item.drugName} × ${item.quantity}'),
                          ),
                        const Divider(),
                        Text('Total: ${order.formattedTotal}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contacting pharmacy...')),
                      );
                    },
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: const Text('Contact Pharmacy'),
                  ),
                  const SizedBox(height: 12),
                  if (order.status != OrderStatus.delivered)
                    OutlinedButton(
                      onPressed: () {
                        context.read<OrderProvider>().cancelOrder(order.id);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Cancel Order'),
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

/// Custom header — back arrow, centered title, headset/support icon —
/// instead of a plain AppBar, so it matches the promo screenshot.
class _TrackOrderHeader extends StatelessWidget {
  final VoidCallback onSupportTap;
  const _TrackOrderHeader({required this.onSupportTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Text(
              'Track Order',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          IconButton(
            tooltip: 'Ask a pharmacist',
            icon: const Icon(Icons.headset_mic_outlined),
            onPressed: onSupportTap,
          ),
        ],
      ),
    );
  }
}

/// The order-number + live-status bar at the top.
class _StatusBanner extends StatelessWidget {
  final String orderId;
  final String headline;
  final bool isDelivered;
  const _StatusBanner({required this.orderId, required this.headline, required this.isDelivered});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Order #$orderId',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              headline,
              style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative route illustration — a dashed curve from the pharmacy to
/// the customer's address, with a rider marker sitting at [progress]
/// along that curve. Not a real map (no API key / GPS), just enough
/// visual storytelling to match the promo design.
class _TrackingMap extends StatelessWidget {
  final double progress;
  final bool isDelivered;
  const _TrackingMap({required this.progress, required this.isDelivered});

  static const double _cardHeight = 190;

  /// Route-curve control points, as fractions of the card's width/height
  /// (0.0–1.0) — named so the curve's shape is readable and tunable in
  /// one place rather than four inline numbers.
  static const double _startXFraction = 0.14;
  static const double _startYFraction = 0.22;
  static const double _endXFraction = 0.86;
  static const double _endYFraction = 0.78;
  static const double _controlXFraction = 0.5;
  static const double _controlYFraction = 0.15;

  static Offset _quadraticBezier(double t, Offset p0, Offset p1, Offset p2) {
    final u = 1 - t;
    final x = u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx;
    final y = u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _cardHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: 0.25)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final p0 = Offset(size.width * _startXFraction, size.height * _startYFraction);
          final p2 = Offset(size.width * _endXFraction, size.height * _endYFraction);
          final p1 = Offset(size.width * _controlXFraction, size.height * _controlYFraction);
          final riderPos = _quadraticBezier(progress.clamp(0.0, 1.0), p0, p1, p2);

          return Stack(
            children: [
              CustomPaint(
                size: size,
                painter: _RoutePainter(p0: p0, p1: p1, p2: p2),
              ),
              Positioned(
                left: p0.dx - 14,
                top: p0.dy - 28,
                child: const _MapPin(icon: Icons.local_pharmacy_outlined),
              ),
              Positioned(
                left: p2.dx - 14,
                top: p2.dy - 28,
                child: const _MapPin(icon: Icons.home_outlined),
              ),
              if (!isDelivered)
                Positioned(
                  left: riderPos.dx - 14,
                  top: riderPos.dy - 14,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: AppTheme.primaryNavy, shape: BoxShape.circle),
                    child: const Icon(Icons.two_wheeler, color: Colors.white, size: 16),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final IconData icon;
  const _MapPin({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(color: AppTheme.primaryNavy, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        CustomPaint(size: const Size(6, 8), painter: _PinTailPainter()),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.primaryNavy;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  final Offset p0;
  final Offset p1;
  final Offset p2;
  const _RoutePainter({required this.p0, required this.p1, required this.p2});

  static const double _dashLength = 6.0;
  static const double _gapLength = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryNavy.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(p0.dx, p0.dy)..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);

    // Manually dash the path by sampling it at fixed arc-length steps.
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = math.min(distance + _dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.p0 != p0 || oldDelegate.p1 != p1 || oldDelegate.p2 != p2;
}

/// "Your Rider" card — avatar initial, name, rating, call/message
/// actions. Rider identity is assigned once (see DemoRider), not a
/// live person, but the card reads the same as the promo design.
class _RiderCard extends StatelessWidget {
  final String name;
  final double rating;
  const _RiderCard({required this.name, required this.rating});

  void _placeholderAction(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action $name...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryNavy,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Rider', style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(rating.toStringAsFixed(1), style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _placeholderAction(context, 'Calling'),
            icon: const Icon(Icons.call_outlined),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.1),
              foregroundColor: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _placeholderAction(context, 'Messaging'),
            icon: const Icon(Icons.chat_bubble_outline),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.08),
              foregroundColor: AppTheme.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }
}

/// One row in the "Order Status" list — checkmark for a completed
/// step, a solid highlighted dot for the current one, an empty dot for
/// steps still ahead, each with its recorded timestamp (or "Pending").
class _TimelineStep extends StatelessWidget {
  final OrderStatus status;
  final Order order;
  final bool isLast;

  const _TimelineStep({required this.status, required this.order, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final currentIndex = order.status.index;
    final stepIndex = status.index;
    final isDone = stepIndex < currentIndex;
    final isCurrent = stepIndex == currentIndex;
    final timestamp = order.timestampFor(status);

    final color = isDone || isCurrent ? AppTheme.primaryNavy : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: isDone
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : isCurrent
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          ),
                        )
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: isDone ? AppTheme.primaryNavy : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status.timelineLabel,
                style: TextStyle(
                  fontWeight: isCurrent || isDone ? FontWeight.w700 : FontWeight.w500,
                  color: isDone || isCurrent ? Theme.of(context).colorScheme.onSurface : Colors.grey,
                ),
              ),
              Text(
                timestamp != null ? _formatStamp(timestamp) : 'Pending',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatStamp(DateTime t) {
    final now = DateTime.now();
    final isToday = t.year == now.year && t.month == now.month && t.day == now.day;
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '${isToday ? 'Today' : '${t.day}/${t.month}'}, $hour12:$minute $period';
  }
}