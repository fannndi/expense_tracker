import 'package:flutter_test/flutter_test.dart';
import 'package:student_expense_tracker/models/wallet.dart';

void main() {
  group('Wallet', () {
    test('default balance is 0', () {
      final wallet = Wallet(id: 'w1', name: 'Cash', type: WalletType.cash);
      expect(wallet.balance, 0);
    });

    test('toJson and fromJson round-trip', () {
      final wallet = Wallet(
        id: 'wal_1',
        name: 'GoPay',
        type: WalletType.eMoney,
        balance: 250000,
      );
      final json = wallet.toJson();
      final restored = Wallet.fromJson(json);

      expect(restored.id, wallet.id);
      expect(restored.name, wallet.name);
      expect(restored.type, wallet.type);
      expect(restored.balance, wallet.balance);
    });

    test('fromJson defaults to cash for unknown type', () {
      final json = {
        'id': 'w1',
        'name': 'Test',
        'type': 'unknown_type',
        'balance': 100,
      };
      final wallet = Wallet.fromJson(json);
      expect(wallet.type, WalletType.cash);
    });

    test('fromJson handles missing balance', () {
      final json = {
        'id': 'w1',
        'name': 'Test',
        'type': 'cash',
      };
      final wallet = Wallet.fromJson(json);
      expect(wallet.balance, 0);
    });

    test('typeDisplayName returns correct labels', () {
      expect(Wallet(id: '1', name: 'A', type: WalletType.cash).typeDisplayName, 'Cash');
      expect(Wallet(id: '2', name: 'B', type: WalletType.eMoney).typeDisplayName, 'E-Money');
      expect(Wallet(id: '3', name: 'C', type: WalletType.debitCredit).typeDisplayName, 'Debit/Credit');
    });

    group('copyWith', () {
      final wallet = Wallet(id: 'w1', name: 'Cash', type: WalletType.cash, balance: 100);

      test('copies specified fields', () {
        final updated = wallet.copyWith(balance: 200, name: 'Updated');
        expect(updated.balance, 200);
        expect(updated.name, 'Updated');
        expect(updated.type, wallet.type);
      });

      test('preserves unchanged fields', () {
        final updated = wallet.copyWith(balance: 999);
        expect(updated.id, wallet.id);
        expect(updated.name, wallet.name);
        expect(updated.type, wallet.type);
      });
    });

    group('equality', () {
      test('equal when ids match', () {
        final a = Wallet(id: 'x', name: 'A', type: WalletType.cash, balance: 1);
        final b = Wallet(id: 'x', name: 'B', type: WalletType.eMoney, balance: 2);
        expect(a, equals(b));
      });

      test('not equal when ids differ', () {
        final a = Wallet(id: 'x', name: 'A', type: WalletType.cash);
        final b = Wallet(id: 'y', name: 'A', type: WalletType.cash);
        expect(a, isNot(equals(b)));
      });
    });
  });
}
