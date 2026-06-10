import 'package:flutter_test/flutter_test.dart';
import 'package:student_expense_tracker/models/expense.dart';
import 'package:student_expense_tracker/models/income.dart';
import 'package:student_expense_tracker/models/wallet.dart';
import 'package:student_expense_tracker/repositories/expense_repository.dart';
import 'package:student_expense_tracker/repositories/income_repository.dart';
import 'package:student_expense_tracker/repositories/wallet_repository.dart';
import 'package:student_expense_tracker/services/storage_service.dart';

class MockStorageService extends StorageService {
  List<Expense> _expenses = [];
  List<Income> _incomes = [];
  List<Wallet> _wallets = [];

  void seedExpenses(List<Expense> expenses) => _expenses = List.from(expenses);
  void seedIncomes(List<Income> incomes) => _incomes = List.from(incomes);
  void seedWallets(List<Wallet> wallets) => _wallets = List.from(wallets);

  @override
  Future<List<Expense>> loadExpenses() async => List.from(_expenses);

  @override
  Future<void> saveExpenses(List<Expense> expenses) async {
    _expenses = List.from(expenses);
  }

  @override
  Future<List<Income>> loadIncomes() async => List.from(_incomes);

  @override
  Future<void> saveIncomes(List<Income> incomes) async {
    _incomes = List.from(incomes);
  }

  @override
  Future<List<Wallet>> loadWallets() async => List.from(_wallets);

  @override
  Future<void> saveWallets(List<Wallet> wallets) async {
    _wallets = List.from(wallets);
  }
}

void main() {
  group('LocalExpenseRepository', () {
    late MockStorageService storage;
    late LocalExpenseRepository repo;

    setUp(() {
      storage = MockStorageService();
      repo = LocalExpenseRepository(storage);
    });

    test('getAll returns empty list initially', () async {
      final result = await repo.getAll();
      expect(result, isEmpty);
    });

    test('add appends expense', () async {
      final expense = Expense(id: 'e1', date: DateTime(2025, 6, 1), category: 'Food', amount: 10000);
      await repo.add(expense);

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'e1');
    });

    test('update replaces existing expense', () async {
      final original = Expense(id: 'e1', date: DateTime(2025, 6, 1), category: 'Food', amount: 10000);
      await repo.add(original);

      final updated = original.copyWith(amount: 20000);
      await repo.update(updated);

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.amount, 20000);
    });

    test('update with non-existent id is a no-op', () async {
      await repo.add(Expense(id: 'e1', date: DateTime(2025, 6, 1), category: 'Food', amount: 10000));

      final ghost = Expense(id: 'e999', date: DateTime(2025, 6, 1), category: 'Food', amount: 99999);
      await repo.update(ghost);

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'e1');
    });

    test('delete removes expense by id', () async {
      await repo.add(Expense(id: 'e1', date: DateTime(2025, 6, 1), category: 'Food', amount: 10000));
      await repo.add(Expense(id: 'e2', date: DateTime(2025, 6, 2), category: 'Fuel', amount: 20000));

      await repo.delete('e1');

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'e2');
    });

    test('delete with non-existent id is a no-op', () async {
      await repo.add(Expense(id: 'e1', date: DateTime(2025, 6, 1), category: 'Food', amount: 10000));
      await repo.delete('e999');

      final all = await repo.getAll();
      expect(all.length, 1);
    });
  });

  group('LocalIncomeRepository', () {
    late MockStorageService storage;
    late LocalIncomeRepository repo;

    setUp(() {
      storage = MockStorageService();
      repo = LocalIncomeRepository(storage);
    });

    test('getAll returns empty list initially', () async {
      expect(await repo.getAll(), isEmpty);
    });

    test('add and getAll round-trip', () async {
      final income = Income(id: 'i1', date: DateTime(2025, 6, 1), type: IncomeType.allowance, amount: 500000);
      await repo.add(income);

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'i1');
    });

    test('update replaces existing income', () async {
      final income = Income(id: 'i1', date: DateTime(2025, 6, 1), type: IncomeType.allowance, amount: 500000);
      await repo.add(income);

      await repo.update(income.copyWith(amount: 600000));
      final all = await repo.getAll();
      expect(all.first.amount, 600000);
    });

    test('delete removes income by id', () async {
      await repo.add(Income(id: 'i1', date: DateTime(2025, 6, 1), type: IncomeType.allowance, amount: 500000));
      await repo.delete('i1');

      expect(await repo.getAll(), isEmpty);
    });
  });

  group('LocalWalletRepository', () {
    late MockStorageService storage;
    late LocalWalletRepository repo;

    setUp(() {
      storage = MockStorageService();
      repo = LocalWalletRepository(storage);
    });

    test('getAll returns empty list initially', () async {
      expect(await repo.getAll(), isEmpty);
    });

    test('add and getAll round-trip', () async {
      final wallet = Wallet(id: 'w1', name: 'Cash', type: WalletType.cash, balance: 100000);
      await repo.add(wallet);

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.name, 'Cash');
    });

    test('update replaces existing wallet', () async {
      final wallet = Wallet(id: 'w1', name: 'Cash', type: WalletType.cash, balance: 100000);
      await repo.add(wallet);

      await repo.update(wallet.copyWith(balance: 200000));
      final all = await repo.getAll();
      expect(all.first.balance, 200000);
    });

    test('delete removes wallet by id', () async {
      await repo.add(Wallet(id: 'w1', name: 'Cash', type: WalletType.cash));
      await repo.delete('w1');

      expect(await repo.getAll(), isEmpty);
    });
  });
}
