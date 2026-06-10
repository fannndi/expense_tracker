import 'package:flutter_test/flutter_test.dart';
import 'package:student_expense_tracker/models/expense_filter.dart';

void main() {
  group('ExpenseFilter', () {
    test('default constructor has all null fields', () {
      const filter = ExpenseFilter();
      expect(filter.year, isNull);
      expect(filter.month, isNull);
      expect(filter.category, isNull);
      expect(filter.searchNote, isNull);
    });

    test('hasActiveFilter is false when no active filters', () {
      const filter = ExpenseFilter(year: 2025, month: 6);
      expect(filter.hasActiveFilter, false);
    });

    test('hasActiveFilter is true when category is set', () {
      const filter = ExpenseFilter(category: 'Food');
      expect(filter.hasActiveFilter, true);
    });

    test('hasActiveFilter is true when searchNote is set', () {
      const filter = ExpenseFilter(searchNote: 'lunch');
      expect(filter.hasActiveFilter, true);
    });

    test('hasActiveFilter is false when searchNote is empty', () {
      const filter = ExpenseFilter(searchNote: '');
      expect(filter.hasActiveFilter, false);
    });

    group('copyWith', () {
      const base = ExpenseFilter(year: 2025, month: 6, category: 'Food', searchNote: 'test');

      test('copies specified fields', () {
        final updated = base.copyWith(year: 2024);
        expect(updated.year, 2024);
        expect(updated.month, 6);
      });

      test('clearCategory sets category to null', () {
        final updated = base.copyWith(clearCategory: true);
        expect(updated.category, isNull);
      });

      test('clearSearchNote sets searchNote to null', () {
        final updated = base.copyWith(clearSearchNote: true);
        expect(updated.searchNote, isNull);
      });

      test('clear flags take precedence over values', () {
        final updated = base.copyWith(category: 'Fuel', clearCategory: true);
        expect(updated.category, isNull);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        const a = ExpenseFilter(year: 2025, month: 6, category: 'Food');
        const b = ExpenseFilter(year: 2025, month: 6, category: 'Food');
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('not equal when any field differs', () {
        const a = ExpenseFilter(year: 2025, month: 6);
        const b = ExpenseFilter(year: 2025, month: 7);
        expect(a, isNot(equals(b)));
      });
    });
  });
}
