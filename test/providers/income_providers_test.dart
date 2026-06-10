import 'package:flutter_test/flutter_test.dart';
import 'package:student_expense_tracker/models/income.dart';
import 'package:student_expense_tracker/providers/income_providers.dart';

void main() {
  group('AllowancePeriod', () {
    test('rangeLabel formats date range', () {
      final period = AllowancePeriod(
        start: DateTime(2025, 1, 15),
        end: DateTime(2025, 2, 14),
        label: 'Allowance - January 2025',
      );

      expect(period.rangeLabel, '15 Jan – 14 Feb');
    });
  });

  group('Allowance periods derivation', () {
    test('creates periods from allowance entries', () {
      final allowances = [
        Income(id: 'i1', date: DateTime(2025, 1, 15), type: IncomeType.allowance, amount: 500000),
        Income(id: 'i2', date: DateTime(2025, 2, 15), type: IncomeType.allowance, amount: 500000),
        Income(id: 'i3', date: DateTime(2025, 3, 15), type: IncomeType.allowance, amount: 500000),
      ];

      allowances.sort((a, b) => a.date.compareTo(b.date));

      expect(allowances.length, 3);
      expect(allowances.first.date, DateTime(2025, 1, 15));
      expect(allowances.last.date, DateTime(2025, 3, 15));
    });

    test('period end is day before next allowance', () {
      final next = DateTime(2025, 2, 15);
      final end = next.subtract(const Duration(days: 1));

      expect(end, DateTime(2025, 2, 14));
    });

    test('filters only allowance type', () {
      final incomes = [
        Income(id: 'i1', date: DateTime(2025, 1, 15), type: IncomeType.allowance, amount: 500000),
        Income(id: 'i2', date: DateTime(2025, 1, 20), type: IncomeType.project, amount: 200000),
        Income(id: 'i3', date: DateTime(2025, 2, 15), type: IncomeType.allowance, amount: 500000),
      ];

      final allowances = incomes.where((i) => i.type == IncomeType.allowance).toList();
      expect(allowances.length, 2);
    });
  });

  group('Income breakdown by type', () {
    test('groups by type for a given month', () {
      final incomes = [
        Income(id: 'i1', date: DateTime(2025, 6, 1), type: IncomeType.allowance, amount: 500000),
        Income(id: 'i2', date: DateTime(2025, 6, 10), type: IncomeType.project, amount: 200000),
        Income(id: 'i3', date: DateTime(2025, 6, 20), type: IncomeType.allowance, amount: 100000),
        Income(id: 'i4', date: DateTime(2025, 5, 1), type: IncomeType.allowance, amount: 500000),
      ];

      final filtered = incomes.where((i) => i.date.year == 2025 && i.date.month == 6);
      final breakdown = <IncomeType, int>{};
      for (final i in filtered) {
        breakdown[i.type] = (breakdown[i.type] ?? 0) + i.amount;
      }

      expect(breakdown[IncomeType.allowance], 600000);
      expect(breakdown[IncomeType.project], 200000);
      expect(breakdown.containsKey(IncomeType.fromPerson), false);
    });
  });

  group('Monthly income total', () {
    test('sums incomes for current month', () {
      final incomes = [
        Income(id: 'i1', date: DateTime(2025, 6, 1), type: IncomeType.allowance, amount: 500000),
        Income(id: 'i2', date: DateTime(2025, 6, 15), type: IncomeType.project, amount: 200000),
        Income(id: 'i3', date: DateTime(2025, 5, 1), type: IncomeType.allowance, amount: 500000),
      ];

      final total = incomes
          .where((i) => i.date.year == 2025 && i.date.month == 6)
          .fold(0, (sum, i) => sum + i.amount);

      expect(total, 700000);
    });
  });
}
