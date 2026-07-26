import '../models/medication_reminder.dart';
import '../models/order.dart';
import '../models/prescription_request.dart';

/// Turns the signed-in customer's own app data (orders, reminders,
/// prescriptions) into a short plain-text block that gets appended to
/// PharmBot's system instruction, so it can answer specific questions
/// like "where's my order?" instead of only giving generic answers.
///
/// Deliberately capped and summarized (not the full objects) to keep
/// the prompt small — this stays friendly to Gemini's free-tier
/// request size and to response latency.
class CustomerContextBuilder {
  CustomerContextBuilder._();

  static const int _maxOrders = 5;

  static String build({
    required List<Order> myOrders,
    required List<MedicationReminder> reminders,
    required List<PrescriptionRequest> myPrescriptions,
  }) {
    if (myOrders.isEmpty && reminders.isEmpty && myPrescriptions.isEmpty) {
      return '';
    }

    final buffer = StringBuffer('Customer context (live from the app):');

    if (myOrders.isNotEmpty) {
      final sorted = [...myOrders]..sort((a, b) => b.orderDate.compareTo(a.orderDate));
      final recent = sorted.take(_maxOrders);
      buffer.writeln();
      buffer.writeln('Recent orders:');
      for (final order in recent) {
        final items = order.items.map((i) => '${i.drugName} x${i.quantity}').join(', ');
        final date = _formatDate(order.orderDate);
        buffer.writeln('- $items — ${order.status.label} ($date)');
      }
    }

    if (reminders.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Active medication reminders:');
      for (final r in reminders) {
        buffer.writeln('- ${r.drugName} (${r.dosage}) at ${r.formattedTime}');
      }
    }

    if (myPrescriptions.isNotEmpty) {
      final sorted = [...myPrescriptions]
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      buffer.writeln();
      buffer.writeln('Prescription submissions:');
      for (final p in sorted.take(3)) {
        final label = p.typedOrder?.isNotEmpty == true
            ? p.typedOrder!
            : (p.hasImage ? 'Photo submission' : 'Submission');
        buffer.writeln('- $label — ${p.status.label} (${_formatDate(p.submittedAt)})');
      }
    }

    return buffer.toString();
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
