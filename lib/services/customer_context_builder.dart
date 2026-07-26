import '../models/drug.dart';
import '../models/medication_reminder.dart';
import '../models/order.dart';
import '../models/prescription_request.dart';

/// Turns the signed-in customer's own app data (orders, reminders,
/// prescriptions) plus the pharmacy's live drug catalog into a short
/// plain-text block that gets appended to PharmBot's system
/// instruction, so it can answer specific questions like "where's my
/// order?" or "do you have paracetamol?" instead of only giving
/// generic answers from its own general knowledge.
///
/// Deliberately capped and summarized (not the full objects) to keep
/// the prompt small — this stays friendly to Gemini's free-tier
/// request size and to response latency.
class CustomerContextBuilder {
  CustomerContextBuilder._();

  static const int _maxOrders = 5;

  /// Caps how many catalog drugs get listed by name in the prompt so
  /// a large inventory doesn't blow up prompt size — if the customer
  /// mentions a drug not in this list, PharmBot is told to say it's
  /// unsure rather than guessing whether it's stocked (see the
  /// instruction appended below the catalog list).
  static const int _maxCatalogDrugs = 150;

  static String build({
    required List<Order> myOrders,
    required List<MedicationReminder> reminders,
    required List<PrescriptionRequest> myPrescriptions,
    List<Drug> catalog = const [],
  }) {
    if (myOrders.isEmpty &&
        reminders.isEmpty &&
        myPrescriptions.isEmpty &&
        catalog.isEmpty) {
      return '';
    }

    final buffer = StringBuffer('Customer context (live from the app):');

    if (catalog.isNotEmpty) {
      final sorted = [...catalog]..sort((a, b) => a.name.compareTo(b.name));
      final listed = sorted.take(_maxCatalogDrugs);
      buffer.writeln();
      buffer.writeln(
        'Pharmacy drug catalog (only these are actually stocked — if a '
        'customer asks about something not listed here, say you\'re not '
        'sure it\'s in stock and suggest they check the Browse/Search '
        'screen or ask a staff member, rather than guessing):',
      );
      for (final drug in listed) {
        final stock = drug.stockStatus == StockStatus.outOfStock
            ? 'out of stock'
            : drug.stockStatus == StockStatus.lowStock
                ? 'low stock'
                : 'in stock';
        buffer.writeln(
          '- ${drug.name} (${drug.category}) — ${drug.formattedPrice}, $stock',
        );
      }
      if (sorted.length > _maxCatalogDrugs) {
        buffer.writeln('...and ${sorted.length - _maxCatalogDrugs} more.');
      }
    }

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
