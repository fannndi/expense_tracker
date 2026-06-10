import 'package:flutter_test/flutter_test.dart';
import 'package:student_expense_tracker/models/income.dart';

void main() {
  group('IncomeType', () {
    test('fromJson parses known types', () {
      expect(IncomeType.fromJson('allowance'), IncomeType.allowance);
      expect(IncomeType.fromJson('from_person'), IncomeType.fromPerson);
      expect(IncomeType.fromJson('project'), IncomeType.project);
      expect(IncomeType.fromJson('other'), IncomeType.other);
    });

    test('fromJson defaults to other for unknown values', () {
      expect(IncomeType.fromJson('unknown'), IncomeType.other);
      expect(IncomeType.fromJson(''), IncomeType.other);
    });

    test('jsonKey round-trips with fromJson', () {
      for (final type in IncomeType.values) {
        expect(IncomeType.fromJson(type.jsonKey), type);
      }
    });

    test('label returns non-empty strings', () {
      for (final type in IncomeType.values) {
        expect(type.label.isNotEmpty, true);
      }
    });
  });

  group('Income', () {
    final income = Income(
      id: 'inc_1',
      date: DateTime(2025, 6, 15),
      type: IncomeType.allowance,
      amount: 500000,
      source: 'Papa',
      note: 'Monthly',
    );

    test('toJson and fromJson round-trip', () {
      final json = income.toJson();
      final restored = Income.fromJson(json);

      expect(restored.id, income.id);
      expect(restored.type, income.type);
      expect(restored.amount, income.amount);
      expect(restored.source, income.source);
      expect(restored.note, income.note);
    });

    test('toJson omits null source and note', () {
      final minimal = Income(
        id: 'inc_2',
        date: DateTime(2025, 1, 1),
        type: IncomeType.other,
        amount: 10000,
      );
      final json = minimal.toJson();

      expect(json.containsKey('source'), false);
      expect(json.containsKey('note'), false);
    });

    test('toJson omits empty source and note', () {
      final inc = Income(
        id: 'inc_3',
        date: DateTime(2025, 1, 1),
        type: IncomeType.other,
        amount: 10000,
        source: '',
        note: '',
      );
      final json = inc.toJson();

      expect(json.containsKey('source'), false);
      expect(json.containsKey('note'), false);
    });

    group('copyWith', () {
      test('copies specified fields', () {
        final updated = income.copyWith(amount: 600000);
        expect(updated.amount, 600000);
        expect(updated.source, income.source);
      });

      test('clearSource sets source to null', () {
        final updated = income.copyWith(clearSource: true);
        expect(updated.source, isNull);
      });

      test('clearNote sets note to null', () {
        final updated = income.copyWith(clearNote: true);
        expect(updated.note, isNull);
      });
    });

    group('equality', () {
      test('equal when ids match', () {
        final a = Income(id: 'x', date: DateTime(2025, 1, 1), type: IncomeType.other, amount: 1);
        final b = Income(id: 'x', date: DateTime(2025, 2, 2), type: IncomeType.project, amount: 2);
        expect(a, equals(b));
      });

      test('not equal when ids differ', () {
        final a = Income(id: 'x', date: DateTime(2025, 1, 1), type: IncomeType.other, amount: 1);
        final b = Income(id: 'y', date: DateTime(2025, 1, 1), type: IncomeType.other, amount: 1);
        expect(a, isNot(equals(b)));
      });
    });
  });
}
