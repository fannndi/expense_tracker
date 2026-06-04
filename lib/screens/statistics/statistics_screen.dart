import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/expense_providers.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'widgets/monthly_trend_chart.dart';
import 'widgets/category_analysis_card.dart';
import 'widgets/report_card.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final trend = ref.watch(monthlyTrendProvider);
    final breakdown = ref.watch(
      categoryBreakdownForMonthProvider(
        (year: selectedMonth.year, month: selectedMonth.month),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
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
            // Monthly trend chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Trend',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last 6 months',
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
            final prev =
                DateTime(selected.year, selected.month - 1);
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
