import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/expense.dart';
import '../models/reminder.dart';
import '../providers/expense_providers.dart';
import '../providers/reminder_providers.dart';
import '../providers/settings_provider.dart';
import '../services/wallet_transaction_service.dart';
import '../utils/category_color.dart';
import '../utils/currency_formatter.dart';
import '../widgets/category_icon.dart';

class TodayRemindersSection extends ConsumerWidget {
  const TodayRemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = AppStrings.forLocale(settings.locale);
    final dueAsync = ref.watch(dueRemindersProvider);
    final expensesAsync = ref.watch(expensesProvider);

    final due = dueAsync.valueOrNull ?? [];
    final expenses = expensesAsync.valueOrNull ?? [];

    if (due.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final unpaid =
        due.where((r) => !_isPaidToday(r, expenses, today)).toList();
    final paid = due.where((r) => _isPaidToday(r, expenses, today)).toList();

    if (unpaid.isEmpty && paid.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined,
                  size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                s.remindersToday,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...unpaid.map((r) => _ReminderCard(
                reminder: r,
                paid: false,
                onPay: () => _handlePay(context, ref, r),
              )),
          ...paid.map((r) => _ReminderCard(
                reminder: r,
                paid: true,
                onPay: null,
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  bool _isPaidToday(
      Reminder reminder, List<Expense> expenses, DateTime today) {
    return expenses.any((e) =>
        e.reminderId == reminder.id &&
        e.date.year == today.year &&
        e.date.month == today.month &&
        e.date.day == today.day);
  }

  Future<void> _handlePay(
      BuildContext context, WidgetRef ref, Reminder reminder) async {
    final now = DateTime.now();
    try {
      await ref
          .read(walletTransactionServiceProvider)
          .addExpenseWithWalletDebit(
            date: now,
            category: reminder.category,
            amount: reminder.amount,
            note: reminder.note != null
                ? '${reminder.title} — ${reminder.note}'
                : reminder.title,
            walletId: reminder.walletId,
            isTransfer: false,
            reminderId: reminder.id,
          );

      final updated = reminder.copyWith(
        nextDueDate: reminder.nextDueFromDate(now),
      );
      await ref.read(remindersProvider.notifier).updateReminder(updated);
      await ref
          .read(reminderNotificationServiceProvider)
          .rescheduleReminder(updated);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final bool paid;
  final VoidCallback? onPay;

  const _ReminderCard({
    required this.reminder,
    required this.paid,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final catColor = CategoryColor.forCategory(reminder.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: paid ? cs.primaryContainer.withAlpha(120) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: catColor.withAlpha(35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CategoryIcon.iconFor(reminder.category),
                color: catColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${CurrencyFormatter.format(reminder.amount)} • ${reminder.category}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (paid)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Paid',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              FilledButton(
                onPressed: onPay,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  textStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Pay'),
              ),
          ],
        ),
      ),
    );
  }
}
