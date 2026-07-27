import 'package:flutter/material.dart';

/// Why a drug's stockQuantity changed. Drives the icon/color and the
/// filter chips on the Stock History screen.
enum StockMovementReason { restock, sale, correction, damage, expired }

extension StockMovementReasonLabel on StockMovementReason {
  String get label {
    switch (this) {
      case StockMovementReason.restock:
        return 'Restock';
      case StockMovementReason.sale:
        return 'Sale';
      case StockMovementReason.correction:
        return 'Correction';
      case StockMovementReason.damage:
        return 'Damage/Loss';
      case StockMovementReason.expired:
        return 'Expired write-off';
    }
  }

  IconData get icon {
    switch (this) {
      case StockMovementReason.restock:
        return Icons.local_shipping_outlined;
      case StockMovementReason.sale:
        return Icons.shopping_bag_outlined;
      case StockMovementReason.correction:
        return Icons.tune_outlined;
      case StockMovementReason.damage:
        return Icons.broken_image_outlined;
      case StockMovementReason.expired:
        return Icons.event_busy_outlined;
    }
  }

  static StockMovementReason fromName(String name) {
    return StockMovementReason.values.firstWhere(
      (r) => r.name == name,
      orElse: () => StockMovementReason.correction,
    );
  }
}

/// A single, append-only entry in the stock audit log — one document
/// per stock change, regardless of whether it came from staff editing
/// the drug form, a quick +/- tap, an explicit restock, a logged
/// damage/expiry write-off, or a customer's order going through.
/// Never updated or deleted after creation (see firestore.rules), so
/// it stays a trustworthy "who changed what, when" record (FR-style
/// accountability requirement staff asked for).
class StockMovement {
  final String id;
  final String drugId;
  final String drugName;

  /// Positive = stock added, negative = stock removed.
  final int delta;

  /// stockQuantity immediately after this movement was applied.
  final int resultingStock;

  final StockMovementReason reason;
  final String staffId;
  final String staffName;
  final String? supplierName;
  final String? note;
  final DateTime timestamp;

  const StockMovement({
    required this.id,
    required this.drugId,
    required this.drugName,
    required this.delta,
    required this.resultingStock,
    required this.reason,
    required this.staffId,
    required this.staffName,
    this.supplierName,
    this.note,
    required this.timestamp,
  });

  bool get isAddition => delta > 0;

  String get formattedDelta => isAddition ? '+$delta' : '$delta';

  factory StockMovement.fromMap(String id, Map<String, dynamic> map) {
    return StockMovement(
      id: id,
      drugId: (map['drugId'] as String?) ?? '',
      drugName: (map['drugName'] as String?) ?? '',
      delta: ((map['delta'] as num?) ?? 0).toInt(),
      resultingStock: ((map['resultingStock'] as num?) ?? 0).toInt(),
      reason: StockMovementReasonLabel.fromName((map['reason'] as String?) ?? 'correction'),
      staffId: (map['staffId'] as String?) ?? '',
      staffName: (map['staffName'] as String?) ?? 'Unknown',
      supplierName: map['supplierName'] as String?,
      note: map['note'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestampMs'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'drugId': drugId,
      'drugName': drugName,
      'delta': delta,
      'resultingStock': resultingStock,
      'reason': reason.name,
      'staffId': staffId,
      'staffName': staffName,
      if (supplierName != null) 'supplierName': supplierName,
      if (note != null) 'note': note,
      'timestampMs': timestamp.millisecondsSinceEpoch,
    };
  }
}
