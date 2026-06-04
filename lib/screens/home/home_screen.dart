import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/expense_providers.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'widgets/category_breakdown_card.dart';
import 'widgets/spending_pie_chart.dart';
import 'widgets/summary_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthLabel = DateFormatter.formatMonthYear(now);
    final monthTotal = ref.watch(currentMonthTotalProvider);
    final todayTotal = ref.watch(todayTotalProvider);
    final breakdown = ref.watch(currentMonthCategoryBreakdownProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Expense Tracker'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(expensesProvider.notifier).reload();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                monthLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            // Summary cards row
            Row(
              children: [
                Expanded(
                  child: monthTotal.when(
                    data: (total) => SummaryCard(
                      label: 'Total Spending',
                      value: CurrencyFormatter.format(total),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    loading: () => const SummaryCard(
                      label: 'Total Spending',
                      value: '...',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    error: (e, _) => const SummaryCard(
                      label: 'Total Spending',
                      value: 'Error',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: todayTotal.when(
                    data: (total) => SummaryCard(
                      label: "Today's Spending",
                      value: CurrencyFormatter.format(total),
                      icon: Icons.today_outlined,
                    ),
                    loading: () => const SummaryCard(
                      label: "Today's Spending",
                      value: '...',
                      icon: Icons.today_outlined,
                    ),
                    error: (e, _) => const SummaryCard(
                      label: "Today's Spending",
                      value: 'Error',
                      icon: Icons.today_outlined,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pie chart
            breakdown.when(
              data: (summaries) => summaries.isEmpty
                  ? const SizedBox.shrink()
                  : SpendingPieChart(summaries: summaries),
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString()),
            ),

            const SizedBox(height: 16),

            // Category breakdown
            breakdown.when(
              data: (summaries) => summaries.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No expenses this month.\nTap + to add one.',
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
                  : CategoryBreakdownCard(summaries: summaries),
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.read(expensesProvider.notifier).reload(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
