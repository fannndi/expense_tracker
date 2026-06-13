import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../models/expense_filter.dart';
import '../models/category_summary.dart';
import '../models/monthly_summary.dart';
import '../repositories/expense_repository.dart';
import '../services/storage_service.dart';

// ─── Infrastructure providers ──────────────────────────────────────────────

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => LocalExpenseRepository(ref.watch(storageServiceProvider)),
);

// ─── Core expenses notifier ───────────────────────────────────────────────

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    return ref.read(expenseRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(expenseRepositoryProvider).getAll(),
    );
  }

  Future<void> addExpense({
    required DateTime date,
    required String category,
    required int amount,
    String? note,
    String? walletId,
    bool isTransfer = false,
    String? reminderId,
  }) async {
    final expense = Expense(
      id: 'exp_${const Uuid().v4()}',
      date: date,
      category: category,
      amount: amount,
      note: note,
      walletId: walletId,
      isTransfer: isTransfer,
      reminderId: reminderId,
    );
    await ref.read(expenseRepositoryProvider).add(expense);
    await reload();
  }

  Future<void> updateExpense(Expense expense) async {
    await ref.read(expenseRepositoryProvider).update(expense);
    await reload();
  }

  Future<void> deleteExpense(String id) async {
    await ref.read(expenseRepositoryProvider).delete(id);
    await reload();
  }
}

final expensesProvider =
    AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(
  ExpensesNotifier.new,
);

// ─── Filter provider ───────────────────────────────────────────────────────

class FilterNotifier extends Notifier<ExpenseFilter> {
  @override
  ExpenseFilter build() {
    final now = DateTime.now();
    return ExpenseFilter(year: now.year, month: now.month);
  }

  void setMonth(int year, int month) {
    state = state.copyWith(year: year, month: month);
  }

  void setCategory(String? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(category: category);
    }
  }

  void setSearchNote(String? text) {
    if (text == null || text.isEmpty) {
      state = state.copyWith(clearSearchNote: true);
    } else {
      state = state.copyWith(searchNote: text);
    }
  }

  void reset() {
    final now = DateTime.now();
    state = ExpenseFilter(year: now.year, month: now.month);
  }
}

final filterProvider = NotifierProvider<FilterNotifier, ExpenseFilter>(
  FilterNotifier.new,
);

// ─── Derived providers ────────────────────────────────────────────────────

/// All expenses sorted newest first
final sortedExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  return ref.watch(expensesProvider).whenData((list) {
    final sorted = List<Expense>.from(list);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  });
});

/// Expenses matching current filter
final filteredExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final filter = ref.watch(filterProvider);
  return ref.watch(sortedExpensesProvider).whenData((list) {
    return list.where((e) {
      final matchYear = filter.year == null || e.date.year == filter.year;
      final matchMonth = filter.month == null || e.date.month == filter.month;
      final matchCat =
          filter.category == null || e.category == filter.category;
      final matchNote = filter.searchNote == null ||
          filter.searchNote!.isEmpty ||
          (e.note?.toLowerCase().contains(filter.searchNote!.toLowerCase()) ??
              false);
      return matchYear && matchMonth && matchCat && matchNote;
    }).toList();
  });
});

/// Expenses for the current month (home screen)
final currentMonthExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final now = DateTime.now();
  return ref.watch(expensesProvider).whenData((list) {
    return list
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
  });
});

/// Today's expenses
final todayExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final now = DateTime.now();
  return ref.watch(expensesProvider).whenData((list) {
    return list
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .toList();
  });
});

/// Total spending for current month (excluding transfers)
final currentMonthTotalProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(currentMonthExpensesProvider).whenData(
        (list) => list.where((e) => !e.isTransfer).fold(0, (sum, e) => sum + e.amount),
      );
});

/// Today's total spending (excluding transfers)
final todayTotalProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(todayExpensesProvider).whenData(
        (list) => list.where((e) => !e.isTransfer).fold(0, (sum, e) => sum + e.amount),
      );
});

/// Category breakdown for current month (excluding transfers)
final currentMonthCategoryBreakdownProvider =
    Provider<AsyncValue<List<CategorySummary>>>((ref) {
  return ref.watch(currentMonthExpensesProvider).whenData((list) {
    final nonTransfers = list.where((e) => !e.isTransfer).toList();
    if (nonTransfers.isEmpty) return [];
    final totals = <String, int>{};
    for (final e in nonTransfers) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    final grandTotal = totals.values.fold(0, (a, b) => a + b);
    final summaries = totals.entries.map((entry) {
      return CategorySummary(
        category: entry.key,
        total: entry.value,
        percentage: grandTotal > 0 ? entry.value / grandTotal * 100 : 0,
      );
    }).toList();
    summaries.sort((a, b) => b.total.compareTo(a.total));
    return summaries;
  });
});

/// Category breakdown for a given month (statistics screen, excluding transfers)
final categoryBreakdownForMonthProvider =
    Provider.family<AsyncValue<List<CategorySummary>>, ({int year, int month})>(
  (ref, params) {
    return ref.watch(expensesProvider).whenData((list) {
      final filtered = list.where(
        (e) =>
            e.date.year == params.year &&
            e.date.month == params.month &&
            !e.isTransfer,
      );
      if (filtered.isEmpty) return [];
      final totals = <String, int>{};
      for (final e in filtered) {
        totals[e.category] = (totals[e.category] ?? 0) + e.amount;
      }
      final grandTotal = totals.values.fold(0, (a, b) => a + b);
      final summaries = totals.entries.map((entry) {
        return CategorySummary(
          category: entry.key,
          total: entry.value,
          percentage: grandTotal > 0 ? entry.value / grandTotal * 100 : 0,
        );
      }).toList();
      summaries.sort((a, b) => b.total.compareTo(a.total));
      return summaries;
    });
  },
);

/// Monthly totals for trend chart (last 6 months, excluding transfers)
final monthlyTrendProvider = Provider<AsyncValue<List<MonthlySummary>>>((ref) {
  return ref.watch(expensesProvider).whenData((list) {
    final now = DateTime.now();
    final summaries = <MonthlySummary>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final total = list
          .where((e) =>
              e.date.year == month.year &&
              e.date.month == month.month &&
              !e.isTransfer)
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

/// Selected month for statistics screen
class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setMonth(DateTime month) {
    state = month;
  }
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);
