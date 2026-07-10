class Medicine {
  final String id;
  final String name;
  final String category;
  final int stock;
  final int reorderLevel;
  final double price;

  const Medicine({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.reorderLevel,
    required this.price,
  });

  bool get isLowStock => stock <= reorderLevel;

  Medicine copyWith({
    String? id,
    String? name,
    String? category,
    int? stock,
    int? reorderLevel,
    double? price,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      price: price ?? this.price,
    );
  }
}
