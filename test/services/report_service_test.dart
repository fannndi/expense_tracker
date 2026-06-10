import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:student_expense_tracker/models/category_summary.dart';
import 'package:student_expense_tracker/models/expense.dart';
import 'package:student_expense_tracker/models/income.dart';
import 'package:student_expense_tracker/services/report_service.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    await initializeDateFormatting('en_US', null);
  });
  group('ReportData', () {
    test('totalSpending excludes auto-fill entries with 0 amount', () {
      final data = ReportData(
        month: DateTime(2025, 6),
        expenses: [
          Expense(id: '1', date: DateTime(2025, 6, 1), category: 'Food', amount: 25000),
          Expense(id: '2', date: DateTime(2025, 6, 2), category: 'Other', amount: 0, isAutoFill: true),
          Expense(id: '3', date: DateTime(2025, 6, 3), category: 'Fuel', amount: 50000),
        ],
        breakdown: [],
      );

      expect(data.totalSpending, 75000);
    });

    test('totalSpending includes auto-fill entries with positive amount', () {
      final data = ReportData(
        month: DateTime(2025, 6),
        expenses: [
          Expense(id: '1', date: DateTime(2025, 6, 1), category: 'Food', amount: 10000, isAutoFill: true),
        ],
        breakdown: [],
      );

      expect(data.totalSpending, 10000);
    });

    test('totalIncome sums all incomes', () {
      final data = ReportData(
        month: DateTime(2025, 6),
        expenses: [],
        breakdown: [],
        incomes: [
          Income(id: '1', date: DateTime(2025, 6, 1), type: IncomeType.allowance, amount: 500000),
          Income(id: '2', date: DateTime(2025, 6, 15), type: IncomeType.project, amount: 200000),
        ],
      );

      expect(data.totalIncome, 700000);
    });

    test('netBalance is income minus spending', () {
      final data = ReportData(
        month: DateTime(2025, 6),
        expenses: [
          Expense(id: '1', date: DateTime(2025, 6, 1), category: 'Food', amount: 100000),
        ],
        breakdown: [],
        incomes: [
          Income(id: '1', date: DateTime(2025, 6, 1), type: IncomeType.allowance, amount: 500000),
        ],
      );

      expect(data.netBalance, 400000);
    });

    test('totalTransactions excludes auto-fill with 0 amount', () {
      final data = ReportData(
        month: DateTime(2025, 6),
        expenses: [
          Expense(id: '1', date: DateTime(2025, 6, 1), category: 'Food', amount: 25000),
          Expense(id: '2', date: DateTime(2025, 6, 2), category: 'Other', amount: 0, isAutoFill: true),
        ],
        breakdown: [],
      );

      expect(data.totalTransactions, 1);
    });
  });

  group('ReportService', () {
    final service = ReportService();

    test('generateTextReport contains app name', () {
      final data = ReportData(
        month: DateTime(2025, 6),
        expenses: [],
        breakdown: [],
      );

      final text = service.generateTextReport(data);
      expect(text, contains('Expense Tracker'));
    });

    test('generateTextReport includes category breakdown', () {
      final data = ReportData(
        month: DateTime(2025, 6),
        expenses: [
          Expense(id: '1', date: DateTime(2025, 6, 1), category: 'Food', amount: 25000),
        ],
        breakdown: [
          const CategorySummary(category: 'Food', total: 25000, percentage: 100),
        ],
      );

      final text = service.generateTextReport(data);
      expect(text, contains('Food'));
      expect(text, contains('100.0%'));
    });

    test('generateTextReport skips auto-fill 0 entries in details', () {
      final data = ReportData(
        month: DateTime(2025, 6),
        expenses: [
          Expense(id: '1', date: DateTime(2025, 6, 1), category: 'Food', amount: 25000),
          Expense(id: '2', date: DateTime(2025, 6, 2), category: 'Other', amount: 0, isAutoFill: true, note: 'Auto-fill'),
        ],
        breakdown: [],
      );

      final text = service.generateTextReport(data);
      expect(text, contains('Food'));
      expect(text, isNot(contains('Auto-fill')));
    });

    test('generatePdfReport returns non-empty bytes', () async {
      final data = ReportData(
        month: DateTime(2025, 6),
        expenses: [
          Expense(id: '1', date: DateTime(2025, 6, 1), category: 'Food', amount: 25000),
        ],
        breakdown: [
          const CategorySummary(category: 'Food', total: 25000, percentage: 100),
        ],
      );

      final pdfBytes = await service.generatePdfReport(data);
      expect(pdfBytes.isNotEmpty, true);
    });
  });
}
