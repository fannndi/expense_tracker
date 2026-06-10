import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../providers/expense_providers.dart';
import '../../providers/income_providers.dart';
import '../../providers/settings_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'widgets/category_analysis_card.dart';
import 'widgets/income_expense_chart.dart';
import 'widgets/monthly_trend_chart.dart';
import 'widgets/report_card.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;

    final selectedMonth = ref.watch(selectedMonthProvider);
    final trend = ref.watch(monthlyTrendProvider);
    final incomeTrend = ref.watch(monthlyIncomeTrendProvider);
    final breakdown = ref.watch(
      categoryBreakdownForMonthProvider(
        (year: selectedMonth.year, month: selectedMonth.month),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(s.statistics),
      ),
      body: trend.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(expensesProvider.notifier).reload(),
        ),
        data: (trendData) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            // Income vs Expense bar chart
            incomeTrend.when(
              data: (incomeData) => IncomeExpenseChart(
                expenseSummaries: trendData,
                incomeSummaries: incomeData,
                incomeLabel: s.income,
                spendingLabel: s.spending,
                locale: settings.locale.languageCode,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Monthly expense trend chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.monthlySpendingTrend,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.last6Months,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    MonthlyTrendChart(summaries: trendData),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Month selector for analysis
            _MonthSelector(selected: selectedMonth),
            const SizedBox(height: 16),

            // Monthly income vs expense summary
            _MonthlyBalanceSummary(month: selectedMonth, strings: s),
            const SizedBox(height: 16),

            // Category analysis
            breakdown.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (summaries) => CategoryAnalysisCard(
                summaries: summaries,
                month: selectedMonth,
              ),
            ),
            const SizedBox(height: 16),

            // Report card
            ReportCard(month: selectedMonth),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends ConsumerWidget {
  final DateTime selected;

  const _MonthSelector({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            final prev = DateTime(selected.year, selected.month - 1);
            ref.read(selectedMonthProvider.notifier).setMonth(prev);
          },
        ),
        Expanded(
          child: Text(
            DateFormatter.formatMonthYear(selected),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            final now = DateTime.now();
            final next = DateTime(selected.year, selected.month + 1);
            if (next.year > now.year ||
                (next.year == now.year && next.month > now.month)) {
              return;
            }
            ref.read(selectedMonthProvider.notifier).setMonth(next);
          },
        ),
      ],
    );
  }
}

class _MonthlyBalanceSummary extends ConsumerWidget {
  final DateTime month;
  final AppStrings strings;

  const _MonthlyBalanceSummary({
    required this.month,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final incomeBreakdown = ref.watch(
      incomeBreakdownForMonthProvider(
        (year: month.year, month: month.month),
      ),
    );
    final expBreakdown = ref.watch(
      categoryBreakdownForMonthProvider(
        (year: month.year, month: month.month),
      ),
    );

    final totalIncome =
        incomeBreakdown.valueOrNull?.values.fold(0, (a, b) => a + b) ?? 0;
    final totalExpense =
        expBreakdown.valueOrNull?.fold(0, (sum, s) => sum + s.total) ?? 0;
    final balance = totalIncome - totalExpense;

    if (totalIncome == 0 && totalExpense == 0) return const SizedBox.shrink();

    final isPositive = balance >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.monthlySummary,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              label: s.income,
              value: CurrencyFormatter.format(totalIncome),
              color: cs.tertiary,
              icon: Icons.arrow_downward_rounded,
            ),
            _SummaryRow(
              label: s.spending,
              value: CurrencyFormatter.format(totalExpense),
              color: cs.error,
              icon: Icons.arrow_upward_rounded,
            ),
            const Divider(height: 20),
            _SummaryRow(
              label: s.balance,
              value:
                  '${balance >= 0 ? '+' : '-'}${CurrencyFormatter.format(balance.abs())}',
              color: isPositive ? cs.tertiary : cs.error,
              icon: isPositive ? Icons.trending_up : Icons.trending_down,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
