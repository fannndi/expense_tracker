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
    return ListTile(
      onTap: onTap,
      leading: CategoryIcon(category: expense.category),
      title: Text(
        expense.category,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      isThreeLine:
          expense.note != null && expense.note!.isNotEmpty,
      trailing: Text(
        CurrencyFormatter.format(expense.amount),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
