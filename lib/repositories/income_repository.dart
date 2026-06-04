import '../models/income.dart';
import '../services/storage_service.dart';

abstract class IncomeRepository {
  Future<List<Income>> getAll();
  Future<void> add(Income income);
  Future<void> update(Income income);
  Future<void> delete(String id);
}

class LocalIncomeRepository implements IncomeRepository {
  final StorageService _storageService;

  LocalIncomeRepository(this._storageService);

  @override
  Future<List<Income>> getAll() => _storageService.loadIncomes();

  @override
  Future<void> add(Income income) async {
    final incomes = await getAll();
    incomes.add(income);
    await _storageService.saveIncomes(incomes);
  }

  @override
  Future<void> update(Income income) async {
    final incomes = await getAll();
    final index = incomes.indexWhere((i) => i.id == income.id);
    if (index == -1) return;
    incomes[index] = income;
    await _storageService.saveIncomes(incomes);
  }

  @override
  Future<void> delete(String id) async {
    final incomes = await getAll();
    incomes.removeWhere((i) => i.id == id);
    await _storageService.saveIncomes(incomes);
  }
}
