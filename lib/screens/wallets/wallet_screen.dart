import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/wallet.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wallet_providers.dart';
import '../../routes/app_router.dart';
import '../../utils/currency_formatter.dart';
import 'widgets/topup_bottom_sheet.dart';
import 'widgets/wallet_card.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s =
        settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;
    final walletsAsync = ref.watch(walletsProvider);
    final totalBalance = ref.watch(totalWalletBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.wallets),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(walletsProvider.notifier).reload();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Total balance card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      s.totalBalance,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    totalBalance.when(
                      data: (total) => Text(
                        CurrencyFormatter.format(total),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Wallet list
            walletsAsync.when(
              data: (wallets) {
                if (wallets.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withAlpha(100),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            s.noWallets,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.createFirstWallet,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    ..._buildSection(
                      context,
                      ref,
                      s,
                      wallets.where((w) => w.type == WalletType.cash).toList(),
                      s.walletTypeCash,
                    ),
                    const SizedBox(height: 16),

                    ..._buildSection(
                      context,
                      ref,
                      s,
                      wallets.where((w) => w.type == WalletType.eMoney).toList(),
                      s.walletTypeEMoney,
                    ),
                    const SizedBox(height: 16),

                    ..._buildSection(
                      context,
                      ref,
                      s,
                      wallets
                          .where((w) => w.type == WalletType.debitCredit)
                          .toList(),
                      s.walletTypeDebitCredit,
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addWallet),
        tooltip: s.addWallet,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildSection(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
    List<Wallet> wallets,
    String title,
  ) {
    if (wallets.isEmpty) return [];
    return [
      Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
      const SizedBox(height: 8),
      ...wallets.map((wallet) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: WalletCard(
              wallet: wallet,
              onTap: () => context.push(AppRoutes.editWallet, extra: wallet),
              onTopUp: () => TopUpBottomSheet.show(
                context,
                ref,
                destinationWallet: wallet,
              ),
            ),
          )),
    ];
  }
}
