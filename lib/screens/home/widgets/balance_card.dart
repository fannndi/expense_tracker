import 'package:flutter/material.dart';

import '../../../utils/currency_formatter.dart';

class BalanceCard extends StatelessWidget {
  final int income;
  final int expense;
  final int balance;

  const BalanceCard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPositive = balance >= 0;

    return Card(
      color: isPositive
          ? Colors.green.shade50
          : Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPositive
              ? Colors.green.shade200
              : Colors.red.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Income
            Expanded(
              child: _BalanceItem(
                label: 'Income',
                value: CurrencyFormatter.format(income),
                icon: Icons.arrow_downward_rounded,
                color: Colors.green.shade600,
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: cs.outlineVariant,
            ),
            // Expense
            Expanded(
              child: _BalanceItem(
                label: 'Spending',
                value: CurrencyFormatter.format(expense),
                icon: Icons.arrow_upward_rounded,
                color: Colors.red.shade600,
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: cs.outlineVariant,
            ),
            // Balance
            Expanded(
              child: _BalanceItem(
                label: 'Balance',
                value: CurrencyFormatter.format(balance.abs()),
                icon: isPositive
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: isPositive
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                prefixSign: isPositive ? '+' : '-',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String prefixSign;

  const _BalanceItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.prefixSign = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$prefixSign$value',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
