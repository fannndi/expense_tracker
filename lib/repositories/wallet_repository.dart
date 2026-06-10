import '../models/wallet.dart';
import '../services/storage_service.dart';

abstract class WalletRepository {
  Future<List<Wallet>> getAll();
  Future<void> add(Wallet wallet);
  Future<void> update(Wallet wallet);
  Future<void> delete(String id);
}

class LocalWalletRepository implements WalletRepository {
  final StorageService _storageService;

  LocalWalletRepository(this._storageService);

  @override
  Future<List<Wallet>> getAll() => _storageService.loadWallets();

  @override
  Future<void> add(Wallet wallet) async {
    final wallets = await getAll();
    wallets.add(wallet);
    await _storageService.saveWallets(wallets);
  }

  @override
  Future<void> update(Wallet wallet) async {
    final wallets = await getAll();
    final index = wallets.indexWhere((w) => w.id == wallet.id);
    if (index == -1) return;
    wallets[index] = wallet;
    await _storageService.saveWallets(wallets);
  }

  @override
  Future<void> delete(String id) async {
    final wallets = await getAll();
    wallets.removeWhere((w) => w.id == id);
    await _storageService.saveWallets(wallets);
  }
}
