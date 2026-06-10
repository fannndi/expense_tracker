import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_expense_tracker/utils/currency_input_formatter.dart';

void main() {
  group('ThousandSeparatorFormatter', () {
    final formatter = ThousandSeparatorFormatter();

    TextEditingValue value(String text) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    group('formatEditUpdate', () {
      test('formats thousands with dots', () {
        final result = formatter.formatEditUpdate(value(''), value('1000'));
        expect(result.text, '1.000');
      });

      test('formats millions with dots', () {
        final result = formatter.formatEditUpdate(value(''), value('1500000'));
        expect(result.text, '1.500.000');
      });

      test('handles empty input', () {
        final result = formatter.formatEditUpdate(value('1'), value(''));
        expect(result.text, '');
      });

      test('handles small numbers without separator', () {
        final result = formatter.formatEditUpdate(value(''), value('999'));
        expect(result.text, '999');
      });

      test('rejects non-numeric input', () {
        final result = formatter.formatEditUpdate(value('123'), value('12a3'));
        expect(result.text, '123');
      });
    });

    group('addThousandSeparator', () {
      test('adds dots correctly', () {
        expect(ThousandSeparatorFormatter.addThousandSeparator('1000'), '1.000');
        expect(ThousandSeparatorFormatter.addThousandSeparator('10000'), '10.000');
        expect(ThousandSeparatorFormatter.addThousandSeparator('100000'), '100.000');
        expect(ThousandSeparatorFormatter.addThousandSeparator('1000000'), '1.000.000');
      });

      test('no separator for small numbers', () {
        expect(ThousandSeparatorFormatter.addThousandSeparator('1'), '1');
        expect(ThousandSeparatorFormatter.addThousandSeparator('99'), '99');
        expect(ThousandSeparatorFormatter.addThousandSeparator('999'), '999');
      });
    });

    group('parseFormatted', () {
      test('parses formatted strings', () {
        expect(ThousandSeparatorFormatter.parseFormatted('1.000'), 1000);
        expect(ThousandSeparatorFormatter.parseFormatted('1.500.000'), 1500000);
      });

      test('parses plain numbers', () {
        expect(ThousandSeparatorFormatter.parseFormatted('15000'), 15000);
      });

      test('returns null for invalid input', () {
        expect(ThousandSeparatorFormatter.parseFormatted('abc'), isNull);
        expect(ThousandSeparatorFormatter.parseFormatted(''), isNull);
      });

      test('handles whitespace', () {
        expect(ThousandSeparatorFormatter.parseFormatted(' 1.000 '), 1000);
      });
    });
  });
}
