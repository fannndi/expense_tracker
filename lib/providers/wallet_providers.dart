import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/wallet.dart';
import '../repositories/wallet_repository.dart';
import 'expense_providers.dart';
import 'income_providers.dart';

// ─── Infrastructure providers ──────────────────────────────────────────────

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => LocalWalletRepository(ref.watch(storageServiceProvider)),
);

// ─── Core wallets notifier ───────────────────────────────────────────────

class WalletsNotifier extends AsyncNotifier<List<Wallet>> {
  @override
  Future<List<Wallet>> build() async {
    return ref.read(walletRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(walletRepositoryProvider).getAll(),
    );
  }

  Future<void> addWallet({
    required String name,
    required WalletType type,
    int initialBalance = 0,
  }) async {
    final wallet = Wallet(
      id: 'wal_${const Uuid().v4()}',
      name: name,
      type: type,
      balance: initialBalance,
    );
    await ref.read(walletRepositoryProvider).add(wallet);
    await reload();
  }

  Future<void> updateWallet(Wallet wallet) async {
    await ref.read(walletRepositoryProvider).update(wallet);
    await reload();
  }

  Future<void> deleteWallet(String id) async {
    await ref.read(walletRepositoryProvider).delete(id);
    await reload();
  }

  /// Kurangi saldo wallet (untuk expense biasa)
  /// Tidak ada pengecekan saldo agar wallet bisa negatif (realistis untuk
  /// kartu kredit / e-money yang mungkin dipakai meski catatan saldo kosong)
  Future<void> debitFromWallet(String walletId, int amount) async {
    final wallets = state.valueOrNull ?? [];
    final wallet = wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => throw Exception('Wallet not found'),
    );
    await updateWallet(wallet.copyWith(balance: wallet.balance - amount));
  }

  /// Tambah saldo wallet (untuk credit dari income atau refund expense)
  Future<void> creditWallet(String walletId, int amount) async {
    final wallets = state.valueOrNull ?? [];
    final wallet = wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => throw Exception('Wallet not found'),
    );
    await updateWallet(wallet.copyWith(balance: wallet.balance + amount));
  }

  /// Tambah saldo wallet (untuk refund saat delete expense)
  Future<void> refundToWallet(String walletId, int amount) async {
    final wallets = state.valueOrNull ?? [];
    final wallet = wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => throw Exception('Wallet not found'),
    );
    await updateWallet(wallet.copyWith(balance: wallet.balance + amount));
  }

  /// Top-up: kurangi source wallet, tambah destination wallet
  Future<void> topUpWallet({
    required String sourceId,
    required String destId,
    required int amount,
  }) async {
    final wallets = state.valueOrNull ?? [];
    final source = wallets.firstWhere(
      (w) => w.id == sourceId,
      orElse: () => throw Exception('Source wallet not found'),
    );
    final dest = wallets.firstWhere(
      (w) => w.id == destId,
      orElse: () => throw Exception('Destination wallet not found'),
    );
    if (source.balance < amount) {
      throw Exception('Insufficient balance');
    }

    // Update kedua wallet sekaligus
    final updatedSource = source.copyWith(balance: source.balance - amount);
    final updatedDest = dest.copyWith(balance: dest.balance + amount);

    await ref.read(walletRepositoryProvider).update(updatedSource);
    await ref.read(walletRepositoryProvider).update(updatedDest);
    await reload();
  }
}

final walletsProvider =
    AsyncNotifierProvider<WalletsNotifier, List<Wallet>>(
  WalletsNotifier.new,
);

// ─── Derived providers ────────────────────────────────────────────────────

/// Total saldo semua wallet (real balance)
final totalWalletBalanceProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(walletsProvider).whenData(
        (list) => list.fold(0, (sum, w) => sum + w.balance),
      );
});

/// Get wallet by ID
final walletByIdProvider =
    Provider.family<AsyncValue<Wallet?>, String>((ref, walletId) {
  return ref.watch(walletsProvider).whenData(
        (list) => list.where((w) => w.id == walletId).firstOrNull,
      );
});

/// Grand total balance: TotalIncome (all time) - TotalExpenses non-transfer (all time)
/// Ini representasi presisi dari seluruh uang yang dimiliki
final grandTotalBalanceProvider = Provider<AsyncValue<int>>((ref) {
  final incomesAsync = ref.watch(incomesProvider);
  final expensesAsync = ref.watch(expensesProvider);

  final totalIncome = incomesAsync.whenData(
    (list) => list.fold(0, (sum, i) => sum + i.amount),
  );
  final totalExpense = expensesAsync.whenData(
    (list) => list
        .where((e) => !e.isTransfer)
        .fold(0, (sum, e) => sum + e.amount),
  );

  return totalIncome.whenData((inc) {
    final exp = totalExpense.valueOrNull ?? 0;
    return inc - exp;
  });
});
