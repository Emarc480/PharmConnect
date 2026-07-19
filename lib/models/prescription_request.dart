enum PrescriptionStatus { pending, reviewed, fulfilled, rejected }

extension PrescriptionStatusLabel on PrescriptionStatus {
  String get label {
    switch (this) {
      case PrescriptionStatus.pending:
        return 'Pending Review';
      case PrescriptionStatus.reviewed:
        return 'Reviewed';
      case PrescriptionStatus.fulfilled:
        return 'Fulfilled';
      case PrescriptionStatus.rejected:
        return 'Rejected';
    }
  }

  static PrescriptionStatus fromName(String name) {
    return PrescriptionStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => PrescriptionStatus.pending,
    );
  }
}

/// A customer-submitted prescription: either a photo of a paper
/// prescription (imageBase64) or a typed-out order (typedOrder), or
/// both. Mirrors the "Upload prescription" / "Type your order" screen
/// — staff review these in the Prescriptions inbox and mark them
/// reviewed/fulfilled once the medicines are prepared.
class PrescriptionRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String? imageBase64;
  final String? typedOrder;
  final String? notes;
  final DateTime submittedAt;
  final PrescriptionStatus status;
  final String? pharmacistNote;

  const PrescriptionRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.imageBase64,
    this.typedOrder,
    this.notes,
    required this.submittedAt,
    this.status = PrescriptionStatus.pending,
    this.pharmacistNote,
  });

  bool get hasImage => imageBase64 != null && imageBase64!.isNotEmpty;

  factory PrescriptionRequest.fromMap(String id, Map<String, dynamic> map) {
    return PrescriptionRequest(
      id: id,
      requesterId: (map['requesterId'] as String?) ?? '',
      requesterName: (map['requesterName'] as String?) ?? '',
      imageBase64: map['imageBase64'] as String?,
      typedOrder: map['typedOrder'] as String?,
      notes: map['notes'] as String?,
      submittedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['submittedAtMs'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      status: PrescriptionStatusLabel.fromName(
        (map['status'] as String?) ?? 'pending',
      ),
      pharmacistNote: map['pharmacistNote'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'imageBase64': imageBase64,
      'typedOrder': typedOrder,
      'notes': notes,
      'submittedAtMs': submittedAt.millisecondsSinceEpoch,
      'status': status.name,
      'pharmacistNote': pharmacistNote,
    };
  }
}