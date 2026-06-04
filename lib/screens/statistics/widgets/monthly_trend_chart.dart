import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/monthly_summary.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/date_formatter.dart';

class MonthlyTrendChart extends StatelessWidget {
  final List<MonthlySummary> summaries;

  const MonthlyTrendChart({super.key, required this.summaries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (summaries.isEmpty) {
      return const SizedBox(height: 160, child: Center(child: Text('No data')));
    }

    final maxY = summaries.fold<double>(
      0,
      (prev, s) => s.total.toDouble() > prev ? s.total.toDouble() : prev,
    );

    final spots = summaries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.total.toDouble());
    }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outlineVariant.withAlpha(100),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= summaries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormatter.formatShortMonth(summaries[index].month),
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    _formatShort(value.toInt()),
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
          minX: 0,
          maxX: (summaries.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: theme.colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: theme.colorScheme.primary,
                  strokeColor: theme.colorScheme.surface,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withAlpha(30),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= summaries.length) return null;
                  final s = summaries[index];
                  return LineTooltipItem(
                    '${DateFormatter.monthName(s.month)}\n${CurrencyFormatter.format(s.total)}',
                    TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatShort(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}jt';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}rb';
    return amount.toString();
  }
}
