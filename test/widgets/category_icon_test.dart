import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_expense_tracker/widgets/category_icon.dart';

void main() {
  testWidgets('CategoryIcon renders correct icon for Food', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryIcon(category: 'Food'),
        ),
      ),
    );

    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
  });

  testWidgets('CategoryIcon renders correct icon for Fuel', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryIcon(category: 'Fuel'),
        ),
      ),
    );

    expect(find.byIcon(Icons.local_gas_station_rounded), findsOneWidget);
  });

  testWidgets('CategoryIcon renders correct icon for Internet', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryIcon(category: 'Internet'),
        ),
      ),
    );

    expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);
  });

  testWidgets('CategoryIcon renders correct icon for Subscription', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryIcon(category: 'Subscription'),
        ),
      ),
    );

    expect(find.byIcon(Icons.subscriptions_rounded), findsOneWidget);
  });

  testWidgets('CategoryIcon renders correct icon for Education', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryIcon(category: 'Education'),
        ),
      ),
    );

    expect(find.byIcon(Icons.school_rounded), findsOneWidget);
  });

  testWidgets('CategoryIcon renders correct icon for Entertainment', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryIcon(category: 'Entertainment'),
        ),
      ),
    );

    expect(find.byIcon(Icons.movie_rounded), findsOneWidget);
  });

  testWidgets('CategoryIcon renders fallback icon for unknown category', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryIcon(category: 'UnknownCategory'),
        ),
      ),
    );

    expect(find.byIcon(Icons.category_rounded), findsOneWidget);
  });

  testWidgets('CategoryIcon respects size parameter', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryIcon(category: 'Food', size: 60),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container).first);
    final constraints = container.constraints;
    expect(constraints?.maxWidth, 60);
    expect(constraints?.maxHeight, 60);
  });
}
