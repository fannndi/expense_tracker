import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _displayFormat = DateFormat('dd MMMM yyyy', 'id_ID');
  static final _monthYearFormat = DateFormat('MMMM yyyy', 'en_US');
  static final _shortMonthFormat = DateFormat('MMM', 'en_US');

  static String formatDisplay(DateTime date) => _displayFormat.format(date);

  static String formatMonthYear(DateTime date) =>
      _monthYearFormat.format(date);

  static String formatShortMonth(int month) {
    final date = DateTime(2024, month);
    return _shortMonthFormat.format(date);
  }

  static String monthName(int month) {
    final date = DateTime(2024, month);
    return DateFormat('MMMM', 'en_US').format(date);
  }
}
