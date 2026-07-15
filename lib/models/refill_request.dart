enum RefillStatus { pending, approved, ready, declined }

extension RefillStatusLabel on RefillStatus {
  String get label {
    switch (this) {
      case RefillStatus.pending:
        return 'Pending';
      case RefillStatus.approved:
        return 'Approved';
      case RefillStatus.ready:
        return 'Ready for Pickup';
      case RefillStatus.declined:
        return 'Declined';
    }
  }
}

class RefillRequest {
  final String id;
  final String drugName;
  final String? notes;
  final DateTime requestDate;
  RefillStatus status;

  RefillRequest({
    required this.id,
    required this.drugName,
    this.notes,
    required this.requestDate,
    this.status = RefillStatus.pending,
  });
}
