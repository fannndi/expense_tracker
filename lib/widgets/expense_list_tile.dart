import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'category_icon.dart';

class ExpenseListTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseListTile({
    super.key,
    required this.expense,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAutoFill = expense.isAutoFill;

    return ListTile(
      onTap: onTap,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CategoryIcon(category: expense.category),
          if (isAutoFill)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'auto',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Text(
            expense.category,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (isAutoFill) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'auto-fill',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormatter.formatDisplay(expense.date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (expense.note != null && expense.note!.isNotEmpty)
            Text(
              expense.note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isAutoFill
                    ? theme.colorScheme.onSurfaceVariant.withAlpha(150)
                    : theme.colorScheme.onSurfaceVariant,
                fontStyle: isAutoFill ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      isThreeLine: expense.note != null && expense.note!.isNotEmpty,
      trailing: Text(
        expense.amount == 0 && isAutoFill
            ? 'Rp 0'
            : CurrencyFormatter.format(expense.amount),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: expense.amount == 0 && isAutoFill
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.primary,
        ),
      ),
    );
  }
}
