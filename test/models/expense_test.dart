import 'package:flutter_test/flutter_test.dart';
import 'package:student_expense_tracker/models/expense.dart';

void main() {
  group('Expense', () {
    final expense = Expense(
      id: 'exp_1',
      date: DateTime(2025, 6, 15, 10, 30),
      category: 'Food',
      amount: 25000,
      note: 'Lunch',
      walletId: 'wal_1',
    );

    test('toJson and fromJson round-trip', () {
      final json = expense.toJson();
      final restored = Expense.fromJson(json);

      expect(restored.id, expense.id);
      expect(restored.category, expense.category);
      expect(restored.amount, expense.amount);
      expect(restored.note, expense.note);
      expect(restored.walletId, expense.walletId);
      expect(restored.isAutoFill, false);
      expect(restored.isTransfer, false);
    });

    test('toJson omits null/empty optional fields', () {
      final minimal = Expense(
        id: 'exp_2',
        date: DateTime(2025, 1, 1),
        category: 'Other',
        amount: 0,
      );
      final json = minimal.toJson();

      expect(json.containsKey('note'), false);
      expect(json.containsKey('isAutoFill'), false);
      expect(json.containsKey('walletId'), false);
      expect(json.containsKey('isTransfer'), false);
    });

    test('toJson includes isAutoFill when true', () {
      final autoFill = Expense(
        id: 'exp_3',
        date: DateTime(2025, 1, 1),
        category: 'Other',
        amount: 0,
        isAutoFill: true,
      );
      expect(autoFill.toJson()['isAutoFill'], true);
    });

    test('toJson includes isTransfer when true', () {
      final transfer = Expense(
        id: 'exp_4',
        date: DateTime(2025, 1, 1),
        category: 'Other',
        amount: 50000,
        isTransfer: true,
      );
      expect(transfer.toJson()['isTransfer'], true);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'exp_5',
        'date': '2025-06-15T10:30:00.000Z',
        'category': 'Food',
        'amount': 15000,
      };
      final e = Expense.fromJson(json);

      expect(e.note, isNull);
      expect(e.isAutoFill, false);
      expect(e.walletId, isNull);
      expect(e.isTransfer, false);
    });

    group('copyWith', () {
      test('copies specified fields', () {
        final updated = expense.copyWith(amount: 30000, note: 'Dinner');
        expect(updated.amount, 30000);
        expect(updated.note, 'Dinner');
        expect(updated.id, expense.id);
        expect(updated.category, expense.category);
      });

      test('clearNote sets note to null', () {
        final updated = expense.copyWith(clearNote: true);
        expect(updated.note, isNull);
      });

      test('clearWalletId sets walletId to null', () {
        final updated = expense.copyWith(clearWalletId: true);
        expect(updated.walletId, isNull);
      });

      test('clearNote takes precedence over note value', () {
        final updated = expense.copyWith(note: 'New', clearNote: true);
        expect(updated.note, isNull);
      });
    });

    group('equality', () {
      test('equal when ids match', () {
        final a = Expense(id: 'x', date: DateTime(2025, 1, 1), category: 'Food', amount: 1);
        final b = Expense(id: 'x', date: DateTime(2025, 2, 2), category: 'Fuel', amount: 2);
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('not equal when ids differ', () {
        final a = Expense(id: 'x', date: DateTime(2025, 1, 1), category: 'Food', amount: 1);
        final b = Expense(id: 'y', date: DateTime(2025, 1, 1), category: 'Food', amount: 1);
        expect(a, isNot(equals(b)));
      });
    });
  });
}
