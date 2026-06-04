import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/category_summary.dart';
import '../../../utils/category_color.dart';
import '../../../utils/currency_formatter.dart';

class SpendingPieChart extends StatefulWidget {
  final List<CategorySummary> summaries;
  final String title;

  const SpendingPieChart({
    super.key,
    required this.summaries,
    this.title = 'Spending Distribution',
  });

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  response == null ||
                                  response.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = response
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _buildSections(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _Legend(summaries: widget.summaries),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return widget.summaries.asMap().entries.map((entry) {
      final i = entry.key;
      final s = entry.value;
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      return PieChartSectionData(
        color: CategoryColor.forCategory(s.category),
        value: s.total.toDouble(),
        title: '${s.percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        showTitle: s.percentage >= 5,
      );
    }).toList();
  }
}

class _Legend extends StatelessWidget {
  final List<CategorySummary> summaries;

  const _Legend({required this.summaries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: summaries.map((s) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: CategoryColor.forCategory(s.category),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.category,
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    CurrencyFormatter.format(s.total),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
