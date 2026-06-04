import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/income.dart';
import '../../providers/income_providers.dart';
import '../../routes/app_router.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final monthTotal = ref.watch(currentMonthIncomeTotalProvider);
    final balance = ref.watch(currentMonthBalanceProvider);
    final incomes = ref.watch(sortedIncomesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(incomesProvider.notifier).reload(),
        child: CustomScrollView(
          slivers: [
            // Summary header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    // Month income card
                    _IncomeMonthCard(
                      month: DateFormatter.formatMonthYear(now),
                      monthTotal: monthTotal,
                      balance: balance,
                    ),
                    const SizedBox(height: 16),

                    // Type breakdown chips
                    _IncomeTypeBreakdown(month: now),
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'All Income',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

            // Income list
            incomes.when(
              loading: () => const SliverFillRemaining(
                child: LoadingView(),
              ),
              error: (e, _) => SliverFillRemaining(
                child: ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.read(incomesProvider.notifier).reload(),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyState(
                      title: 'No income recorded yet',
                      subtitle: 'Tap + to add your allowance or other income.',
                      icon: Icons.savings_outlined,
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= list.length) return null;
                      final income = list[index];
                      return Column(
                        children: [
                          _IncomeTile(
                            income: income,
                            onTap: () => context.push(
                              AppRoutes.editIncome,
                              extra: income,
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                    childCount: list.length,
                  ),
                );
              },
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }
}

// ─── Summary card ──────────────────────────────────────────────────────────

class _IncomeMonthCard extends StatelessWidget {
  final String month;
  final AsyncValue<int> monthTotal;
  final AsyncValue<int> balance;

  const _IncomeMonthCard({
    required this.month,
    required this.monthTotal,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              month,
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onPrimaryContainer.withAlpha(180),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Income',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer.withAlpha(160),
                        ),
                      ),
                      const SizedBox(height: 2),
                      monthTotal.when(
                        data: (v) => Text(
                          CurrencyFormatter.format(v),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        loading: () => Text(
                          '...',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        error: (_, __) => const Text('Error'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Balance',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer.withAlpha(160),
                        ),
                      ),
                      const SizedBox(height: 2),
                      balance.when(
                        data: (v) => Text(
                          CurrencyFormatter.format(v),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: v >= 0
                                ? Colors.green.shade300
                                : Colors.red.shade300,
                          ),
                        ),
                        loading: () => Text(
                          '...',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        error: (_, __) => const Text('Error'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Type breakdown ────────────────────────────────────────────────────────

class _IncomeTypeBreakdown extends ConsumerWidget {
  final DateTime month;

  const _IncomeTypeBreakdown({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(
      incomeBreakdownForMonthProvider(
        (year: month.year, month: month.month),
      ),
    );
    final theme = Theme.of(context);

    return breakdown.when(
      data: (map) {
        if (map.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: map.entries.map((entry) {
            return Chip(
              avatar: Icon(
                _iconForType(entry.key),
                size: 16,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                '${entry.key.label}: ${CurrencyFormatter.format(entry.value)}',
                style: theme.textTheme.labelSmall,
              ),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  IconData _iconForType(IncomeType type) {
    switch (type) {
      case IncomeType.allowance:
        return Icons.home_outlined;
      case IncomeType.fromPerson:
        return Icons.person_outline;
      case IncomeType.project:
        return Icons.work_outline;
      case IncomeType.other:
        return Icons.more_horiz;
    }
  }
}

// ─── Income tile ───────────────────────────────────────────────────────────

class _IncomeTile extends StatelessWidget {
  final Income income;
  final VoidCallback? onTap;

  const _IncomeTile({required this.income, this.onTap});

  IconData _iconForType(IncomeType type) {
    switch (type) {
      case IncomeType.allowance:
        return Icons.home_outlined;
      case IncomeType.fromPerson:
        return Icons.person_outline;
      case IncomeType.project:
        return Icons.work_outline;
      case IncomeType.other:
        return Icons.category_outlined;
    }
  }

  Color _colorForType(IncomeType type) {
    switch (type) {
      case IncomeType.allowance:
        return const Color(0xFF1565C0);
      case IncomeType.fromPerson:
        return const Color(0xFF2E7D32);
      case IncomeType.project:
        return const Color(0xFFE65100);
      case IncomeType.other:
        return const Color(0xFF6A1B9A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorForType(income.type);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_iconForType(income.type), color: color, size: 22),
      ),
      title: Text(
        income.type.label +
            (income.source != null && income.source!.isNotEmpty
                ? ' – ${income.source}'
                : ''),
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormatter.formatDisplay(income.date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (income.note != null && income.note!.isNotEmpty)
            Text(
              income.note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      isThreeLine: income.note != null && income.note!.isNotEmpty,
      trailing: Text(
        CurrencyFormatter.format(income.amount),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.green.shade600,
        ),
      ),
    );
  }
}
