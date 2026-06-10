import 'package:flutter_test/flutter_test.dart';
import 'package:student_expense_tracker/models/expense.dart';

void main() {
  group('Filtered expenses', () {
    final expenses = [
      Expense(id: 'e1', date: DateTime(2025, 6, 1), category: 'Food', amount: 25000),
      Expense(id: 'e2', date: DateTime(2025, 6, 15), category: 'Fuel', amount: 50000),
      Expense(id: 'e3', date: DateTime(2025, 5, 1), category: 'Food', amount: 30000),
      Expense(id: 'e4', date: DateTime(2025, 6, 20), category: 'Food', amount: 15000, note: 'Lunch with team'),
    ];

    test('filters by year and month', () {
      final filtered = expenses.where((e) {
        return e.date.year == 2025 && e.date.month == 6;
      }).toList();

      expect(filtered.length, 3);
    });

    test('filters by category', () {
      final filtered = expenses.where((e) => e.category == 'Food').toList();
      expect(filtered.length, 3);
    });

    test('filters by note search', () {
      final filtered = expenses.where((e) {
        return e.note?.toLowerCase().contains('lunch') ?? false;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, 'e4');
    });

    test('combined filters', () {
      final filtered = expenses.where((e) {
        final matchMonth = e.date.year == 2025 && e.date.month == 6;
        final matchCat = e.category == 'Food';
        return matchMonth && matchCat;
      }).toList();

      expect(filtered.length, 2);
    });
  });

  group('Category breakdown', () {
    test('calculates correct percentages', () {
      final expenses = [
        Expense(id: 'e1', date: DateTime(2025, 6, 1), category: 'Food', amount: 75000),
        Expense(id: 'e2', date: DateTime(2025, 6, 2), category: 'Fuel', amount: 25000),
      ];

      final totals = <String, int>{};
      for (final e in expenses) {
        totals[e.category] = (totals[e.category] ?? 0) + e.amount;
      }
      final grandTotal = totals.values.fold(0, (a, b) => a + b);

      expect(grandTotal, 100000);
      expect(totals['Food']! / grandTotal * 100, 75.0);
      expect(totals['Fuel']! / grandTotal * 100, 25.0);
    });

    test('excludes transfers from breakdown', () {
      final expenses = [
        Expense(id: 'e1', date: DateTime(2025, 6, 1), category: 'Food', amount: 25000),
        Expense(id: 'e2', date: DateTime(2025, 6, 2), category: 'Other', amount: 100000, isTransfer: true),
      ];

      final nonTransfers = expenses.where((e) => !e.isTransfer).toList();
      expect(nonTransfers.length, 1);
      expect(nonTransfers.first.amount, 25000);
    });
  });

  group('Monthly trend', () {
    test('computes 6-month window', () {
      final now = DateTime(2025, 6, 15);
      final months = <DateTime>[];
      for (int i = 5; i >= 0; i--) {
        months.add(DateTime(now.year, now.month - i));
      }

      expect(months.length, 6);
      expect(months.first, DateTime(2025, 1));
      expect(months.last, DateTime(2025, 6));
    });
  });

  group('Transfer exclusion', () {
    test('current month total excludes transfers', () {
      final expenses = [
        Expense(id: 'e1', date: DateTime(2025, 6, 1), category: 'Food', amount: 25000),
        Expense(id: 'e2', date: DateTime(2025, 6, 2), category: 'Other', amount: 100000, isTransfer: true),
        Expense(id: 'e3', date: DateTime(2025, 6, 3), category: 'Fuel', amount: 50000),
      ];

      final total = expenses
          .where((e) => !e.isTransfer && e.date.month == 6)
          .fold(0, (sum, e) => sum + e.amount);

      expect(total, 75000);
    });
  });
}
