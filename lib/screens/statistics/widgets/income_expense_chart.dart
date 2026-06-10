import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/monthly_summary.dart';
import '../../../utils/currency_abbreviator.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/date_formatter.dart';

class IncomeExpenseChart extends StatelessWidget {
  final List<MonthlySummary> expenseSummaries;
  final List<MonthlySummary> incomeSummaries;
  final String incomeLabel;
  final String spendingLabel;
  final String locale;

  const IncomeExpenseChart({
    super.key,
    required this.expenseSummaries,
    required this.incomeSummaries,
    this.incomeLabel = 'Income',
    this.spendingLabel = 'Spending',
    this.locale = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Check if there's any income data worth showing
    final hasIncome = incomeSummaries.any((s) => s.total > 0);
    if (!hasIncome && expenseSummaries.every((s) => s.total == 0)) {
      return const SizedBox.shrink();
    }

    final maxY = [
      ...expenseSummaries.map((s) => s.total),
      ...incomeSummaries.map((s) => s.total),
    ].fold<double>(0, (prev, v) => v.toDouble() > prev ? v.toDouble() : prev);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              incomeLabel.isNotEmpty && spendingLabel.isNotEmpty
                  ? '$incomeLabel vs $spendingLabel'
                  : 'Income vs Spending',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _LegendDot(color: cs.tertiary, label: incomeLabel),
                const SizedBox(width: 16),
                _LegendDot(color: cs.primary, label: spendingLabel),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxY * 1.2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: cs.outlineVariant.withAlpha(80),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= expenseSummaries.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormatter.formatShortMonth(
                                  expenseSummaries[i].month),
                              style: theme.textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            CurrencyAbbreviator.abbreviate(value.toInt(), locale: locale),
                            style: theme.textTheme.labelSmall,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(expenseSummaries.length, (i) {
                    final income = i < incomeSummaries.length
                        ? incomeSummaries[i].total.toDouble()
                        : 0.0;
                    final expense = expenseSummaries[i].total.toDouble();
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: cs.tertiary,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: expense,
                          color: cs.primary,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label =
                            rodIndex == 0 ? incomeLabel : spendingLabel;
                        return BarTooltipItem(
                          '$label\n${CurrencyFormatter.format(rod.toY.toInt())}',
                          TextStyle(
                            color: cs.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
