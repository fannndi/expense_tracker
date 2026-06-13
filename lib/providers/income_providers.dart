import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/income.dart';
import '../models/monthly_summary.dart';
import '../repositories/income_repository.dart';
import 'expense_providers.dart';
import 'wallet_providers.dart';

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
    String? walletId,
  }) async {
    final income = Income(
      id: 'inc_${const Uuid().v4()}',
      date: date,
      type: type,
      amount: amount,
      source: source,
      note: note,
      walletId: walletId,
    );
    await ref.read(incomeRepositoryProvider).add(income);

    if (walletId != null) {
      try {
        await ref
            .read(walletsProvider.notifier)
            .creditWallet(walletId, amount);
      } catch (e) {
        await ref.read(incomeRepositoryProvider).delete(income.id);
        rethrow;
      }
    }

    await reload();
  }

  Future<void> updateIncome(Income updated) async {
    final oldIncome = await ref.read(incomeRepositoryProvider).getAll().then(
          (list) => list.firstWhere((i) => i.id == updated.id),
        );

    await ref.read(incomeRepositoryProvider).update(updated);

    try {
      // Refund old wallet (reverse original credit)
      if (oldIncome.walletId != null) {
        await ref
            .read(walletsProvider.notifier)
            .debitFromWallet(oldIncome.walletId!, oldIncome.amount);
      }
      // Credit new wallet
      if (updated.walletId != null) {
        await ref
            .read(walletsProvider.notifier)
            .creditWallet(updated.walletId!, updated.amount);
      }
    } catch (e) {
      // Rollback: restore old income in storage
      await ref.read(incomeRepositoryProvider).update(oldIncome);
      rethrow;
    }

    await reload();
  }

  Future<void> deleteIncome(String id) async {
    final income = await ref.read(incomeRepositoryProvider).getAll().then(
          (list) => list.firstWhere((i) => i.id == id),
        );

    await ref.read(incomeRepositoryProvider).delete(id);

    if (income.walletId != null) {
      try {
        await ref
            .read(walletsProvider.notifier)
            .debitFromWallet(income.walletId!, income.amount);
      } catch (e) {
        await ref.read(incomeRepositoryProvider).add(income);
        rethrow;
      }
    }

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

// ─── Allowance periods ────────────────────────────────────────────────────

class AllowancePeriod {
  final DateTime start;
  final DateTime end;
  final String label;

  const AllowancePeriod({
    required this.start,
    required this.end,
    required this.label,
  });

  String get rangeLabel {
    final fmt = DateFormat('d MMM', 'en_US');
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }
}

final allowancePeriodsProvider = Provider<List<AllowancePeriod>>((ref) {
  final incomesAsync = ref.watch(incomesProvider);
  final allIncomes = incomesAsync.valueOrNull ?? [];

  final allowances = allIncomes
      .where((i) => i.type == IncomeType.allowance)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  if (allowances.isEmpty) return [];

  final today = DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);

  final periods = <AllowancePeriod>[];
  for (int i = 0; i < allowances.length; i++) {
    final start = DateTime(
      allowances[i].date.year,
      allowances[i].date.month,
      allowances[i].date.day,
    );
    final DateTime end;
    if (i + 1 < allowances.length) {
      final next = allowances[i + 1].date;
      end = DateTime(next.year, next.month, next.day)
          .subtract(const Duration(days: 1));
    } else {
      end = todayMidnight.subtract(const Duration(days: 1));
    }
    if (end.isBefore(start)) continue;

    final monthLabel = DateFormat('MMMM yyyy', 'en_US').format(start);
    final label = 'Allowance – $monthLabel';
    periods.add(AllowancePeriod(start: start, end: end, label: label));
  }

  periods.sort((a, b) => b.start.compareTo(a.start));
  return periods;
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
