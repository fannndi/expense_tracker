import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_expense_tracker/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: StudentExpenseTrackerApp(),
      ),
    );
    expect(find.byType(StudentExpenseTrackerApp), findsOneWidget);
  });
}
