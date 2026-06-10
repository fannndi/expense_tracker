import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_expense_tracker/main.dart';

void main() {
  testWidgets('App smoke test - renders without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: StudentExpenseTrackerApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
