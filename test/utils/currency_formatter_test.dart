import 'package:flutter_test/flutter_test.dart';
import 'package:student_expense_tracker/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    group('format', () {
      test('formats zero', () {
        expect(CurrencyFormatter.format(0), 'Rp 0');
      });

      test('formats small amounts', () {
        expect(CurrencyFormatter.format(1000), 'Rp 1.000');
        expect(CurrencyFormatter.format(15000), 'Rp 15.000');
      });

      test('formats large amounts with thousand separators', () {
        expect(CurrencyFormatter.format(1500000), 'Rp 1.500.000');
        expect(CurrencyFormatter.format(100000000), 'Rp 100.000.000');
      });

      test('formats single digits', () {
        expect(CurrencyFormatter.format(1), 'Rp 1');
        expect(CurrencyFormatter.format(999), 'Rp 999');
      });
    });

    group('parse', () {
      test('parses formatted string', () {
        expect(CurrencyFormatter.parse('Rp 15.000'), 15000);
        expect(CurrencyFormatter.parse('Rp 1.500.000'), 1500000);
      });

      test('parses plain number', () {
        expect(CurrencyFormatter.parse('15000'), 15000);
      });

      test('returns null for invalid input', () {
        expect(CurrencyFormatter.parse('abc'), isNull);
        expect(CurrencyFormatter.parse(''), isNull);
      });

      test('round-trips with format', () {
        final values = [0, 1, 999, 15000, 1500000, 100000000];
        for (final v in values) {
          expect(CurrencyFormatter.parse(CurrencyFormatter.format(v)), v);
        }
      });
    });
  });
}
