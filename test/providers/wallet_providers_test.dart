import 'package:flutter_test/flutter_test.dart';
import 'package:student_expense_tracker/models/expense.dart';
import 'package:student_expense_tracker/models/income.dart';
import 'package:student_expense_tracker/models/wallet.dart';

void main() {
  group('Grand total balance', () {
    test('equals totalIncome minus totalExpenses (non-transfer)', () {
      final incomes = [
        Income(id: 'i1', date: DateTime(2025, 1, 1), type: IncomeType.allowance, amount: 500000),
        Income(id: 'i2', date: DateTime(2025, 2, 1), type: IncomeType.allowance, amount: 500000),
      ];
      final expenses = [
        Expense(id: 'e1', date: DateTime(2025, 1, 5), category: 'Food', amount: 100000),
        Expense(id: 'e2', date: DateTime(2025, 1, 10), category: 'Other', amount: 200000, isTransfer: true),
        Expense(id: 'e3', date: DateTime(2025, 2, 5), category: 'Fuel', amount: 50000),
      ];

      final totalIncome = incomes.fold(0, (sum, i) => sum + i.amount);
      final totalExpense = expenses.where((e) => !e.isTransfer).fold(0, (sum, e) => sum + e.amount);
      final grandTotal = totalIncome - totalExpense;

      expect(totalIncome, 1000000);
      expect(totalExpense, 150000);
      expect(grandTotal, 850000);
    });
  });

  group('Total wallet balance', () {
    test('sums all wallet balances', () {
      final wallets = [
        Wallet(id: 'w1', name: 'Cash', type: WalletType.cash, balance: 200000),
        Wallet(id: 'w2', name: 'GoPay', type: WalletType.eMoney, balance: 150000),
        Wallet(id: 'w3', name: 'BCA', type: WalletType.debitCredit, balance: 500000),
      ];

      final total = wallets.fold(0, (sum, w) => sum + w.balance);
      expect(total, 850000);
    });

    test('returns 0 for empty wallet list', () {
      final total = <Wallet>[].fold(0, (sum, w) => sum + w.balance);
      expect(total, 0);
    });
  });

  group('Wallet operations', () {
    test('debit reduces balance', () {
      final wallet = Wallet(id: 'w1', name: 'Cash', type: WalletType.cash, balance: 100000);
      final debited = wallet.copyWith(balance: wallet.balance - 30000);
      expect(debited.balance, 70000);
    });

    test('refund increases balance', () {
      final wallet = Wallet(id: 'w1', name: 'Cash', type: WalletType.cash, balance: 70000);
      final refunded = wallet.copyWith(balance: wallet.balance + 30000);
      expect(refunded.balance, 100000);
    });

    test('topUp transfers between wallets', () {
      final source = Wallet(id: 'w1', name: 'Cash', type: WalletType.cash, balance: 200000);
      final dest = Wallet(id: 'w2', name: 'GoPay', type: WalletType.eMoney, balance: 50000);

      final amount = 100000;
      final updatedSource = source.copyWith(balance: source.balance - amount);
      final updatedDest = dest.copyWith(balance: dest.balance + amount);

      expect(updatedSource.balance, 100000);
      expect(updatedDest.balance, 150000);
    });

    test('insufficient balance check', () {
      final wallet = Wallet(id: 'w1', name: 'Cash', type: WalletType.cash, balance: 50000);
      expect(wallet.balance < 100000, true);
    });
  });
}
