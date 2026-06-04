import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../providers/expense_providers.dart';
import '../../providers/income_providers.dart';
import '../../providers/settings_provider.dart';
import '../../routes/app_router.dart';
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
          ]);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Hero balance section
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

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
