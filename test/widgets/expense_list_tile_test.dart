import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:student_expense_tracker/widgets/expense_list_tile.dart';
import 'package:student_expense_tracker/models/expense.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    await initializeDateFormatting('en_US', null);
  });

  testWidgets('ExpenseListTile renders category and amount', (tester) async {
    final expense = Expense(
      id: 'e1',
      date: DateTime(2025, 6, 15),
      category: 'Food',
      amount: 25000,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ExpenseListTile(expense: expense),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Food'), findsOneWidget);
    expect(find.textContaining('25.000'), findsOneWidget);
  });

  testWidgets('ExpenseListTile shows auto-fill badge', (tester) async {
    final expense = Expense(
      id: 'e1',
      date: DateTime(2025, 6, 15),
      category: 'Other',
      amount: 0,
      isAutoFill: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ExpenseListTile(expense: expense),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('auto'), findsOneWidget);
  });

  testWidgets('ExpenseListTile shows note when present', (tester) async {
    final expense = Expense(
      id: 'e1',
      date: DateTime(2025, 6, 15),
      category: 'Food',
      amount: 25000,
      note: 'Lunch with friends',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ExpenseListTile(expense: expense),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Lunch with friends'), findsOneWidget);
  });
}
