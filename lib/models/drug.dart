/// Single source of truth for a pharmacy drug/medicine record.
///
/// This replaces the old split between `Drug` (customer catalog) and
/// `Medicine` (staff inventory) — both screens now read and write the
/// same Firestore-backed model, so a stock change made by staff in
/// Inventory is immediately reflected in the customer-facing catalog.
///
/// Matches the ERD's DRUG entity: drug_id, name, description, price,
/// stock_quantity, category (reorder_level is an added field used to
/// drive low-stock alerts, per FR11). discountPercent is an optional
/// staff-set promo (0 = no discount) that drives the strikethrough
/// price and the Home "Offers" rail. imageBase64 is an optional photo
/// staff attach — stored inline the same way PrescriptionRequest
/// stores its photo, small enough to stay well under Firestore's 1MB
/// document cap while avoiding a Cloud Storage dependency.
library;

enum StockStatus { inStock, lowStock, outOfStock }

class Drug {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stockQuantity;
  final int reorderLevel;
  final int discountPercent;
  final String? imageBase64;
  final String? countryOfOrigin; // ISO 3166-1 alpha-2 code, e.g. 'UG'
  final String? manufacturer; // e.g. 'Cipla'

  const Drug({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stockQuantity,
    this.description = '',
    this.reorderLevel = 10,
    this.discountPercent = 0,
    this.imageBase64,
    this.countryOfOrigin,
    this.manufacturer,
  });

  /// Stock status is always derived from live stockQuantity — never
  /// stored separately — so it can never drift out of sync (FR3).
  StockStatus get stockStatus {
    if (stockQuantity <= 0) return StockStatus.outOfStock;
    if (stockQuantity <= reorderLevel) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  bool get isLowStock => stockStatus != StockStatus.inStock;

  int get unitsAvailable => stockQuantity;

  bool get hasDiscount => discountPercent > 0 && discountPercent < 100;

  bool get hasImage => imageBase64 != null && imageBase64!.isNotEmpty;

  /// The pre-discount price, derived from the live (already
  /// discounted) `price` — so staff only ever edit one number.
  double get originalPrice =>
      hasDiscount ? price / (1 - (discountPercent / 100)) : price;

  String get formattedPrice => _formatUgx(price);

  String get formattedOriginalPrice => _formatUgx(originalPrice);

  String _formatUgx(double amount) {
    final s = amount.round().toString();
    final withCommas = s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return "UGX $withCommas";
  }

  String get stockLabel {
    switch (stockStatus) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
    }
  }

  Drug copyWith({
    String? name,
    String? description,
    String? category,
    double? price,
    int? stockQuantity,
    int? reorderLevel,
    int? discountPercent,
    String? imageBase64,
    String? countryOfOrigin,
    String? manufacturer,
  }) {
    return Drug(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      discountPercent: discountPercent ?? this.discountPercent,
      imageBase64: imageBase64 ?? this.imageBase64,
      countryOfOrigin: countryOfOrigin ?? this.countryOfOrigin,
      manufacturer: manufacturer ?? this.manufacturer,
    );
  }

  factory Drug.fromMap(String id, Map<String, dynamic> map) {
    return Drug(
      id: id,
      name: (map['name'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'Uncategorized',
      price: ((map['price'] as num?) ?? 0).toDouble(),
      stockQuantity: ((map['stockQuantity'] as num?) ?? 0).toInt(),
      reorderLevel: ((map['reorderLevel'] as num?) ?? 10).toInt(),
      discountPercent: ((map['discountPercent'] as num?) ?? 0).toInt(),
      imageBase64: map['imageBase64'] as String?,
      countryOfOrigin: map['countryOfOrigin'] as String?,
      manufacturer: map['manufacturer'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'stockQuantity': stockQuantity,
      'reorderLevel': reorderLevel,
      'discountPercent': discountPercent,
      'imageBase64': imageBase64,
      'countryOfOrigin': countryOfOrigin,
      'manufacturer': manufacturer,
    };
  }
}