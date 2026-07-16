import 'package:flutter/foundation.dart';
import '../models/drug.dart';
import '../models/order.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, int> _quantities = {}; // drugId -> quantity
  final Map<String, Drug> _drugs = {}; // drugId -> Drug snapshot

  List<OrderItem> get items => _quantities.entries
      .map((e) => OrderItem.fromDrug(_drugs[e.key]!, e.value))
      .toList();

  int get itemCount => _quantities.values.fold(0, (a, b) => a + b);

  double get total => items.fold(0.0, (sum, item) => sum + item.subtotal);

  String get formattedTotal {
    final s = total.round().toString();
    final withCommas = s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return "UGX $withCommas";
  }

  int quantityOf(String drugId) => _quantities[drugId] ?? 0;

  void addToCart(Drug drug, {int quantity = 1}) {
    _drugs[drug.id] = drug;
    _quantities[drug.id] = (_quantities[drug.id] ?? 0) + quantity;
    notifyListeners();
  }

  void setQuantity(Drug drug, int quantity) {
    if (quantity <= 0) {
      removeFromCart(drug.id);
      return;
    }
    _drugs[drug.id] = drug;
    _quantities[drug.id] = quantity;
    notifyListeners();
  }

  /// Same as [setQuantity] but for callers that only have the drugId
  /// (e.g. the Cart screen updating a stepper) — the Drug snapshot is
  /// already cached from when the item was added, so no lookup elsewhere
  /// is needed.
  void setQuantityById(String drugId, int quantity) {
    final drug = _drugs[drugId];
    if (drug == null) return;
    setQuantity(drug, quantity);
  }

  void removeFromCart(String drugId) {
    _quantities.remove(drugId);
    _drugs.remove(drugId);
    notifyListeners();
  }

  void clear() {
    _quantities.clear();
    _drugs.clear();
    notifyListeners();
  }
}
