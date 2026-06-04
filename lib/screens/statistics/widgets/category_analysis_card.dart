import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_strings.dart';
import '../../../models/category_summary.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/category_color.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/date_formatter.dart';
import '../../../widgets/empty_state.dart';

class CategoryAnalysisCard extends ConsumerWidget {
  final List<CategorySummary> summaries;
  final DateTime month;

  const CategoryAnalysisCard({
    super.key,
    required this.summaries,
    required this.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (summaries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            title: s.noDataFor(DateFormatter.formatMonthYear(month)),
            icon: Icons.bar_chart_outlined,
          ),
        ),
      );
    }

    final highest = summaries.first;
    final lowest = summaries.last;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.categoryAnalysis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Highlight cards
            Row(
              children: [
                Expanded(
                  child: _HighlightChip(
                    label: s.highest,
                    category: highest.category,
                    amount: highest.total,
                    icon: Icons.trending_up,
                    color: cs.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HighlightChip(
                    label: s.lowest,
                    category: lowest.category,
                    amount: lowest.total,
                    icon: Icons.trending_down,
                    color: cs.tertiary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Detailed list
            ...summaries.map((sum) => _DetailRow(summary: sum)),
          ],
        ),
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  final String label;
  final String category;
  final int amount;
  final IconData icon;
  final Color color;

  const _HighlightChip({
    required this.label,
    required this.category,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(category,
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(CurrencyFormatter.format(amount),
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final CategorySummary summary;

  const _DetailRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = CategoryColor.forCategory(summary.category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(summary.category, style: theme.textTheme.bodyMedium),
          ),
          Text(
            '${summary.percentage.toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            CurrencyFormatter.format(summary.total),
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
