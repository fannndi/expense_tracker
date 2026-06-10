import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_expense_tracker/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState renders icon and title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No items',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('No items'), findsOneWidget);
  });

  testWidgets('EmptyState renders subtitle when provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No items',
            subtitle: 'Tap + to add one',
          ),
        ),
      ),
    );

    expect(find.text('Tap + to add one'), findsOneWidget);
  });

  testWidgets('EmptyState does not render subtitle when null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No items',
          ),
        ),
      ),
    );

    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    expect(textWidgets.length, 1);
  });
}
