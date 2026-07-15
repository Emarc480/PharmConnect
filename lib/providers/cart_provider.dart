import 'package:flutter/foundation.dart';
import '../models/drug.dart';
import '../models/order.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, int> _quantities = {}; // drugId -> quantity
  final Map<String, Drug> _drugs = {}; // drugId -> Drug snapshot

  List<OrderItem> get items => _quantities.entries
      .map((e) => OrderItem(drug: _drugs[e.key]!, quantity: e.value))
      .toList();

  int get itemCount => _quantities.values.fold(0, (a, b) => a + b);

  int get total =>
      items.fold(0, (sum, item) => sum + item.subtotal);

  String get formattedTotal {
    final s = total.toString();
    final withCommas = s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'UGX $withCommas';
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
