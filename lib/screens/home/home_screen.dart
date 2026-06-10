import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../providers/expense_providers.dart';
import '../../providers/income_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wallet_providers.dart';
import '../../routes/app_router.dart';
import '../../utils/constants.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/share_pdf_bottom_sheet.dart';
import 'widgets/balance_card.dart';
import 'widgets/category_breakdown_card.dart';
import 'widgets/spending_pie_chart.dart';
import 'widgets/summary_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;

    final now = DateTime.now();
    final monthLabel = DateFormatter.formatMonthYear(now);
    final monthTotal = ref.watch(currentMonthTotalProvider);
    final todayTotal = ref.watch(todayTotalProvider);
    final incomeTotal = ref.watch(currentMonthIncomeTotalProvider);
    final balance = ref.watch(currentMonthBalanceProvider);
    final breakdown = ref.watch(currentMonthCategoryBreakdownProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appName),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: s.sharePdf,
            onPressed: () => SharePdfBottomSheet.show(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: s.settings,
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(expensesProvider.notifier).reload(),
            ref.read(incomesProvider.notifier).reload(),
            ref.read(walletsProvider.notifier).reload(),
          ]);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Total balance (all time)
            const TotalBalanceSection(),
            const SizedBox(height: 8),

            // Hero balance section (monthly)
            balance.when(
              data: (bal) => incomeTotal.when(
                data: (inc) => monthTotal.when(
                  data: (exp) => HeroSection(
                    income: inc,
                    expense: exp,
                    balance: bal,
                    monthLabel: monthLabel,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const Divider(height: 1),
            const SizedBox(height: 16),

            // Summary cards row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: monthTotal.when(
                      data: (total) => SummaryCard(
                        label: s.totalSpending,
                        value: CurrencyFormatter.format(total),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      loading: () => SummaryCard(
                        label: s.totalSpending,
                        value: '...',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      error: (e, _) => SummaryCard(
                        label: s.totalSpending,
                        value: '-',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: todayTotal.when(
                      data: (total) => SummaryCard(
                        label: s.todaySpending,
                        value: CurrencyFormatter.format(total),
                        icon: Icons.today_outlined,
                      ),
                      loading: () => SummaryCard(
                        label: s.todaySpending,
                        value: '...',
                        icon: Icons.today_outlined,
                      ),
                      error: (e, _) => SummaryCard(
                        label: s.todaySpending,
                        value: '-',
                        icon: Icons.today_outlined,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Pie chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: breakdown.when(
                data: (summaries) => summaries.isEmpty
                    ? const SizedBox.shrink()
                    : SpendingPieChart(
                        summaries: summaries,
                        title: s.spendingDistribution,
                      ),
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(message: e.toString()),
              ),
            ),

            const SizedBox(height: 16),

            // Category breakdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: breakdown.when(
                data: (summaries) => summaries.isEmpty
                    ? Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              s.noExpensesThisMonth,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                      )
                    : CategoryBreakdownCard(
                        summaries: summaries,
                        title: s.monthlyBreakdown,
                      ),
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.read(expensesProvider.notifier).reload(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Wallet summary section
            _WalletSummarySection(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _WalletSummarySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final walletsAsync = ref.watch(walletsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.wallets,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.wallets),
                child: Text(s.all),
              ),
            ],
          ),
          const SizedBox(height: 8),
          walletsAsync.when(
            data: (wallets) {
              if (wallets.isEmpty) {
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push(AppRoutes.addWallet),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 32,
                              color: cs.onSurfaceVariant.withAlpha(100),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.createFirstWallet,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: wallets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final wallet = wallets[index];
                    final color = AppConstants.colorForWalletType(wallet.type);
                    final icon = AppConstants.iconForWalletType(wallet.type);

                    return SizedBox(
                      width: 160,
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.push(AppRoutes.wallets),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: color.withAlpha(30),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(icon, color: color, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        wallet.name,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  CurrencyFormatter.format(wallet.balance),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
