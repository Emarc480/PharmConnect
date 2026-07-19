/// A recurring daily medication reminder ("Your today pills"): a drug
/// name, dose, and one or more times of day, plus which calendar days
/// it's been marked taken on. Deliberately simple (no push
/// notifications) — the in-app "Reminders" screen is the source of
/// truth, matching the reference "Reminder" calendar-strip screen.
class MedicationReminder {
  final String id;
  final String ownerId;
  final String drugName;
  final String dosage;
  final int hour;
  final int minute;
  final List<String> takenOnDates;

  const MedicationReminder({
    required this.id,
    required this.ownerId,
    required this.drugName,
    required this.dosage,
    required this.hour,
    required this.minute,
    this.takenOnDates = const [],
  });

  static String keyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool isTakenOn(DateTime date) => takenOnDates.contains(keyFor(date));

  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${h12.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }

  factory MedicationReminder.fromMap(String id, Map<String, dynamic> map) {
    return MedicationReminder(
      id: id,
      ownerId: (map['ownerId'] as String?) ?? '',
      drugName: (map['drugName'] as String?) ?? '',
      dosage: (map['dosage'] as String?) ?? '1 per intake',
      hour: ((map['hour'] as num?) ?? 8).toInt(),
      minute: ((map['minute'] as num?) ?? 0).toInt(),
      takenOnDates:
          ((map['takenOnDates'] as List<dynamic>?) ?? const []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'drugName': drugName,
      'dosage': dosage,
      'hour': hour,
      'minute': minute,
      'takenOnDates': takenOnDates,
    };
  }
}