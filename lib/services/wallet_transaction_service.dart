import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../providers/expense_providers.dart';
import '../providers/wallet_providers.dart';

class WalletTransactionService {
  final Ref _ref;

  WalletTransactionService(this._ref);

  Future<void> addExpenseWithWalletDebit({
    required DateTime date,
    required String category,
    required int amount,
    String? note,
    String? walletId,
    bool isTransfer = false,
  }) async {
    await _ref.read(expensesProvider.notifier).addExpense(
          date: date,
          category: category,
          amount: amount,
          note: note,
          walletId: walletId,
          isTransfer: isTransfer,
        );

    if (walletId != null && !isTransfer) {
      try {
        await _ref.read(walletsProvider.notifier).debitFromWallet(walletId, amount);
      } catch (e) {
        final lastId = await _findLastExpenseId(date, category, amount);
        await _ref.read(expensesProvider.notifier).deleteExpense(lastId);
        rethrow;
      }
    }
  }

  Future<void> updateExpenseWithWallet({
    required Expense original,
    required Expense updated,
  }) async {
    final oldWalletId = original.walletId;
    final newWalletId = updated.walletId;
    final oldIsTransfer = original.isTransfer;
    final newIsTransfer = updated.isTransfer;

    if (oldWalletId != null && !oldIsTransfer) {
      await _ref
          .read(walletsProvider.notifier)
          .refundToWallet(oldWalletId, original.amount);
    }

    try {
      await _ref.read(expensesProvider.notifier).updateExpense(updated);
    } catch (e) {
      if (oldWalletId != null && !oldIsTransfer) {
        await _ref
            .read(walletsProvider.notifier)
            .debitFromWallet(oldWalletId, original.amount);
      }
      rethrow;
    }

    if (newWalletId != null && !newIsTransfer) {
      try {
        await _ref
            .read(walletsProvider.notifier)
            .debitFromWallet(newWalletId, updated.amount);
      } catch (e) {
        await _ref.read(expensesProvider.notifier).updateExpense(original);
        if (oldWalletId != null && !oldIsTransfer) {
          await _ref
              .read(walletsProvider.notifier)
              .debitFromWallet(oldWalletId, original.amount);
        }
        rethrow;
      }
    }
  }

  Future<void> deleteExpenseWithRefund(Expense expense) async {
    final walletId = expense.walletId;
    if (walletId != null && !expense.isTransfer) {
      await _ref
          .read(walletsProvider.notifier)
          .refundToWallet(walletId, expense.amount);
    }

    try {
      await _ref.read(expensesProvider.notifier).deleteExpense(expense.id);
    } catch (e) {
      if (walletId != null && !expense.isTransfer) {
        await _ref
            .read(walletsProvider.notifier)
            .debitFromWallet(walletId, expense.amount);
      }
      rethrow;
    }
  }

  Future<void> topUpWithRecord({
    required String sourceId,
    required String destId,
    required int amount,
    required String destName,
  }) async {
    await _ref.read(walletsProvider.notifier).topUpWallet(
          sourceId: sourceId,
          destId: destId,
          amount: amount,
        );

    try {
      await _ref.read(expensesProvider.notifier).addExpense(
            date: DateTime.now(),
            category: 'Other',
            amount: amount,
            note: 'Top-up $destName',
            walletId: destId,
            isTransfer: true,
          );
    } catch (e) {
      final wallets = _ref.read(walletsProvider).valueOrNull ?? [];
      final source = wallets.firstWhere(
        (w) => w.id == sourceId,
        orElse: () => wallets.first,
      );
      final dest = wallets.firstWhere(
        (w) => w.id == destId,
        orElse: () => wallets.first,
      );
      await _ref.read(walletsProvider.notifier).updateWallet(
            source.copyWith(balance: source.balance + amount),
          );
      await _ref.read(walletsProvider.notifier).updateWallet(
            dest.copyWith(balance: dest.balance - amount),
          );
      await _ref.read(walletsProvider.notifier).reload();
      rethrow;
    }
  }

  Future<String> _findLastExpenseId(
    DateTime date,
    String category,
    int amount,
  ) async {
    final expenses = _ref.read(expensesProvider).valueOrNull ?? [];
    final match = expenses.lastWhere(
      (e) =>
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day &&
          e.category == category &&
          e.amount == amount,
      orElse: () => expenses.last,
    );
    return match.id;
  }
}

final walletTransactionServiceProvider = Provider<WalletTransactionService>(
  (ref) => WalletTransactionService(ref),
);
