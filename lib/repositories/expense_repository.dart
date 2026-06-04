import '../models/expense.dart';
import '../services/storage_service.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getAll();
  Future<void> add(Expense expense);
  Future<void> update(Expense expense);
  Future<void> delete(String id);
}

class LocalExpenseRepository implements ExpenseRepository {
  final StorageService _storageService;

  LocalExpenseRepository(this._storageService);

  @override
  Future<List<Expense>> getAll() => _storageService.loadExpenses();

  @override
  Future<void> add(Expense expense) async {
    final expenses = await getAll();
    expenses.add(expense);
    await _storageService.saveExpenses(expenses);
  }

  @override
  Future<void> update(Expense expense) async {
    final expenses = await getAll();
    final index = expenses.indexWhere((e) => e.id == expense.id);
    if (index == -1) return;
    expenses[index] = expense;
    await _storageService.saveExpenses(expenses);
  }

  @override
  Future<void> delete(String id) async {
    final expenses = await getAll();
    expenses.removeWhere((e) => e.id == id);
    await _storageService.saveExpenses(expenses);
  }
}
