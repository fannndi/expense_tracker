import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../providers/expense_providers.dart';
import '../utils/constants.dart';

/// Mengecek hari-hari weekday yang belum ada expense sama sekali
/// dan menambahkan entry auto-fill Rp 0 untuk hari-hari tersebut.
///
/// Dipanggil saat:
/// 1. App pertama kali dibuka (main.dart)
/// 2. App resume dari background
class AutoFillChecker {
  final Ref _ref;

  AutoFillChecker(this._ref);

  /// Cek dan fill entry untuk:
  /// - Hari ini jika sudah jam >= 23:00 dan weekday
  /// - Hingga 7 hari ke belakang yang belum ter-fill
  ///
  /// Returns list tanggal yang baru di-fill.
  Future<List<DateTime>> checkAndFill() async {
    final now = DateTime.now();
    final repo = _ref.read(expenseRepositoryProvider);
    final filled = <DateTime>[];

    // Ambil semua expenses (sekali baca saja)
    final allExpenses = await repo.getAll();

    for (int daysAgo = 0; daysAgo <= 6; daysAgo++) {
      final checkDate = now.subtract(Duration(days: daysAgo));

      // Skip weekend
      if (checkDate.weekday == DateTime.saturday ||
          checkDate.weekday == DateTime.sunday) {
        continue;
      }

      // Untuk hari ini: hanya fill jika sudah jam 23:00+
      if (daysAgo == 0 && now.hour < AppConstants.autoFillHour) {
        continue;
      }

      // Apakah sudah ada entry hari itu?
      final hasEntry = allExpenses.any((e) =>
          e.date.year == checkDate.year &&
          e.date.month == checkDate.month &&
          e.date.day == checkDate.day);

      if (!hasEntry) {
        final entry = Expense(
          id: 'autofill_${const Uuid().v4()}',
          date: DateTime(
            checkDate.year,
            checkDate.month,
            checkDate.day,
            AppConstants.autoFillHour,
            AppConstants.autoFillMinute,
          ),
          category: AppConstants.autoFillCategory,
          amount: 0,
          note: 'Auto-fill (tidak ada pengeluaran)',
          isAutoFill: true,
        );
        await repo.add(entry);
        filled.add(checkDate);
        debugPrint(
            '[AutoFill] Inserted Rp 0 entry: ${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}');
      }
    }

    // Jika ada yang baru di-fill, reload expenses provider
    if (filled.isNotEmpty) {
      await _ref.read(expensesProvider.notifier).reload();
    }

    return filled;
  }
}

final autoFillCheckerProvider = Provider<AutoFillChecker>(
  (ref) => AutoFillChecker(ref),
);
