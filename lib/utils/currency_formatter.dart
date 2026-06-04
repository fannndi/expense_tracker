import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat('#,###', 'id_ID');

  /// Format amount as Indonesian Rupiah: Rp 15.000
  static String format(int amount) {
    final formatted = _formatter.format(amount);
    // Replace comma (intl id_ID uses comma as thousand separator on some systems)
    // Ensure dot is used as thousand separator per Indonesian standard
    final normalized = formatted.replaceAll(',', '.');
    return 'Rp $normalized';
  }

  /// Parse "Rp 15.000" or "15000" back to int
  static int? parse(String value) {
    final cleaned = value
        .replaceAll('Rp', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .trim();
    return int.tryParse(cleaned);
  }
}
