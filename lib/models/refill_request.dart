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

  static RefillStatus fromName(String name) {
    return RefillStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => RefillStatus.pending,
    );
  }
}

class RefillRequest {
  final String id;
  final String requesterId;
  final String drugName;
  final String? notes;
  final DateTime requestDate;
  RefillStatus status;

  RefillRequest({
    required this.id,
    required this.requesterId,
    required this.drugName,
    this.notes,
    required this.requestDate,
    this.status = RefillStatus.pending,
  });

  factory RefillRequest.fromMap(String id, Map<String, dynamic> map) {
    return RefillRequest(
      id: id,
      requesterId: (map['requesterId'] as String?) ?? '',
      drugName: (map['drugName'] as String?) ?? '',
      notes: map['notes'] as String?,
      requestDate: DateTime.fromMillisecondsSinceEpoch(
        (map['requestDateMs'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      status: RefillStatusLabel.fromName((map['status'] as String?) ?? 'pending'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'drugName': drugName,
      'notes': notes,
      'requestDateMs': requestDate.millisecondsSinceEpoch,
      'status': status.name,
    };
  }
}
