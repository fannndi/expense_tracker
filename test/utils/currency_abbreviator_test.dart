import 'package:flutter_test/flutter_test.dart';
import 'package:student_expense_tracker/utils/currency_abbreviator.dart';

void main() {
  group('CurrencyAbbreviator', () {
    group('English locale', () {
      test('abbreviates millions', () {
        expect(CurrencyAbbreviator.abbreviate(1500000, locale: 'en'), '1.5M');
        expect(CurrencyAbbreviator.abbreviate(2000000, locale: 'en'), '2M');
        expect(CurrencyAbbreviator.abbreviate(10000000, locale: 'en'), '10M');
      });

      test('abbreviates thousands', () {
        expect(CurrencyAbbreviator.abbreviate(15000, locale: 'en'), '15K');
        expect(CurrencyAbbreviator.abbreviate(150000, locale: 'en'), '150K');
        expect(CurrencyAbbreviator.abbreviate(999000, locale: 'en'), '999K');
      });

      test('returns raw number for small amounts', () {
        expect(CurrencyAbbreviator.abbreviate(0, locale: 'en'), '0');
        expect(CurrencyAbbreviator.abbreviate(500, locale: 'en'), '500');
        expect(CurrencyAbbreviator.abbreviate(999, locale: 'en'), '999');
      });
    });

    group('Indonesian locale', () {
      test('abbreviates millions as jt', () {
        expect(CurrencyAbbreviator.abbreviate(1500000, locale: 'id'), '1.5jt');
        expect(CurrencyAbbreviator.abbreviate(2000000, locale: 'id'), '2jt');
        expect(CurrencyAbbreviator.abbreviate(10000000, locale: 'id'), '10jt');
      });

      test('abbreviates thousands as rb', () {
        expect(CurrencyAbbreviator.abbreviate(15000, locale: 'id'), '15rb');
        expect(CurrencyAbbreviator.abbreviate(150000, locale: 'id'), '150rb');
      });

      test('returns raw number for small amounts', () {
        expect(CurrencyAbbreviator.abbreviate(999, locale: 'id'), '999');
      });
    });

    test('defaults to English for unknown locale', () {
      expect(CurrencyAbbreviator.abbreviate(1500000, locale: 'fr'), '1.5M');
    });
  });
}
