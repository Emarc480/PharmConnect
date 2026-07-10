enum StockStatus { inStock, lowStock, outOfStock }

class Drug{
  final String id;
  final String name;
  final int priceUgx;
  final StockStatus stockStatus;
  final int unitsAvailable;
  final String category;
  final String? imageUrl; //Check this one later

  Drug({
    required this.id,
    required this.name,
    required this.priceUgx,
    required this.stockStatus,
    required this.unitsAvailable,
    required this.category,
    this.imageUrl,
  });

  String get formattedPrice {
    final s = priceUgx.toString();
    final withCommas = s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},'
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
}