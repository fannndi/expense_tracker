import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/income.dart';
import '../models/monthly_summary.dart';
import '../repositories/income_repository.dart';
import 'expense_providers.dart';

// ─── Infrastructure ────────────────────────────────────────────────────────

final incomeRepositoryProvider = Provider<IncomeRepository>(
  (ref) => LocalIncomeRepository(ref.watch(storageServiceProvider)),
);

// ─── Core income notifier ─────────────────────────────────────────────────

class IncomesNotifier extends AsyncNotifier<List<Income>> {
  @override
  Future<List<Income>> build() async {
    return ref.read(incomeRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(incomeRepositoryProvider).getAll(),
    );
  }

  Future<void> addIncome({
    required DateTime date,
    required IncomeType type,
    required int amount,
    String? source,
    String? note,
  }) async {
    final income = Income(
      id: 'inc_${const Uuid().v4()}',
      date: date,
      type: type,
      amount: amount,
      source: source,
      note: note,
    );
    await ref.read(incomeRepositoryProvider).add(income);
    await reload();
  }

  Future<void> updateIncome(Income income) async {
    await ref.read(incomeRepositoryProvider).update(income);
    await reload();
  }

  Future<void> deleteIncome(String id) async {
    await ref.read(incomeRepositoryProvider).delete(id);
    await reload();
  }
}

final incomesProvider =
    AsyncNotifierProvider<IncomesNotifier, List<Income>>(
  IncomesNotifier.new,
);

// ─── Derived providers ────────────────────────────────────────────────────

/// All incomes sorted newest first
final sortedIncomesProvider = Provider<AsyncValue<List<Income>>>((ref) {
  return ref.watch(incomesProvider).whenData((list) {
    final sorted = List<Income>.from(list);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  });
});

/// Incomes for current month
final currentMonthIncomesProvider = Provider<AsyncValue<List<Income>>>((ref) {
  final now = DateTime.now();
  return ref.watch(incomesProvider).whenData((list) {
    return list
        .where((i) => i.date.year == now.year && i.date.month == now.month)
        .toList();
  });
});

/// Total income current month
final currentMonthIncomeTotalProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(currentMonthIncomesProvider).whenData(
        (list) => list.fold(0, (sum, i) => sum + i.amount),
      );
});

/// Net balance current month (income - expense)
final currentMonthBalanceProvider = Provider<AsyncValue<int>>((ref) {
  final income = ref.watch(currentMonthIncomeTotalProvider);
  final expense = ref.watch(currentMonthTotalProvider);
  return income.whenData((inc) {
    final exp = expense.valueOrNull ?? 0;
    return inc - exp;
  });
});

/// Monthly income totals for trend chart (last 6 months)
final monthlyIncomeTrendProvider =
    Provider<AsyncValue<List<MonthlySummary>>>((ref) {
  return ref.watch(incomesProvider).whenData((list) {
    final now = DateTime.now();
    final summaries = <MonthlySummary>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final total = list
          .where((e) =>
              e.date.year == month.year && e.date.month == month.month)
          .fold(0, (sum, e) => sum + e.amount);
      summaries.add(MonthlySummary(
        year: month.year,
        month: month.month,
        total: total,
      ));
    }
    return summaries;
  });
});

/// Income breakdown by type for a given month
final incomeBreakdownForMonthProvider =
    Provider.family<AsyncValue<Map<IncomeType, int>>, ({int year, int month})>(
  (ref, params) {
    return ref.watch(incomesProvider).whenData((list) {
      final filtered = list.where(
        (i) => i.date.year == params.year && i.date.month == params.month,
      );
      final result = <IncomeType, int>{};
      for (final i in filtered) {
        result[i.type] = (result[i.type] ?? 0) + i.amount;
      }
      return result;
    });
  },
);
