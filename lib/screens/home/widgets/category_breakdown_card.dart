import 'package:flutter/material.dart';

import '../../../models/category_summary.dart';
import '../../../utils/category_color.dart';
import '../../../utils/currency_formatter.dart';

class CategoryBreakdownCard extends StatelessWidget {
  final List<CategorySummary> summaries;

  const CategoryBreakdownCard({super.key, required this.summaries});

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
              'Monthly Breakdown',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...summaries.map((s) => _CategoryRow(summary: s)),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategorySummary summary;

  const _CategoryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = CategoryColor.forCategory(summary.category);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  summary.category,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                CurrencyFormatter.format(summary.total),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: summary.percentage / 100,
              backgroundColor: color.withAlpha(40),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
