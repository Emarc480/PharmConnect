import 'package:flutter/foundation.dart';
import '../models/refill_request.dart';

class RefillProvider extends ChangeNotifier {
  final List<RefillRequest> _requests = [
    RefillRequest(
      id: 'RF-1001',
      drugName: 'Amoxicillin 250mg',
      notes: 'Ran out this morning, need before evening dose.',
      requestDate: DateTime.now().subtract(const Duration(hours: 5)),
      status: RefillStatus.pending,
    ),
  ];

  List<RefillRequest> get requests => List.unmodifiable(_requests.reversed);

  List<RefillRequest> get pending =>
      _requests.where((r) => r.status == RefillStatus.pending).toList().reversed.toList();

  int get pendingCount => _requests.where((r) => r.status == RefillStatus.pending).length;

  RefillRequest submitRequest({required String drugName, String? notes}) {
    final request = RefillRequest(
      id: 'RF-${1000 + _requests.length + 1}',
      drugName: drugName,
      notes: notes,
      requestDate: DateTime.now(),
    );
    _requests.add(request);
    notifyListeners();
    return request;
  }

  void updateStatus(String id, RefillStatus status) {
    final request = _requests.firstWhere((r) => r.id == id);
    request.status = status;
    notifyListeners();
  }
}
