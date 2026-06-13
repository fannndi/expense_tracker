import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/app_strings.dart';
import '../../models/reminder.dart';
import '../../providers/reminder_providers.dart';
import '../../providers/settings_provider.dart';
import '../../services/wallet_transaction_service.dart';
import 'widgets/expense_form.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  bool _loading = false;

  Future<void> _onSave({
    required int amount,
    required String category,
    required DateTime date,
    String? note,
    String? walletId,
    bool isTransfer = false,
    ReminderData? reminderData,
  }) async {
    final settings = ref.read(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;

    setState(() => _loading = true);
    try {
      await ref.read(walletTransactionServiceProvider).addExpenseWithWalletDebit(
            date: date,
            category: category,
            amount: amount,
            note: note,
            walletId: walletId,
            isTransfer: isTransfer,
          );

      if (reminderData != null && !isTransfer) {
        final title = note ?? s.categoryDisplayName(category);
        final now = DateTime.now();
        final nextDueDate = _computeInitialNextDueDate(reminderData);

        final id = 'rem_${const Uuid().v4()}';
        final reminder = Reminder(
          id: id,
          title: title,
          category: category,
          amount: amount,
          note: note,
          walletId: walletId,
          recurrence: reminderData.recurrence,
          dayOfMonth: reminderData.dayOfMonth,
          customIntervalDays: reminderData.customIntervalDays,
          nextDueDate: nextDueDate,
          isActive: true,
          createdAt: now,
          notificationId: Reminder.notificationIdFor(id),
        );

        await ref.read(remindersProvider.notifier).addReminder(
              title: reminder.title,
              category: reminder.category,
              amount: reminder.amount,
              note: reminder.note,
              walletId: reminder.walletId,
              recurrence: reminder.recurrence,
              dayOfMonth: reminder.dayOfMonth,
              customIntervalDays: reminder.customIntervalDays,
              nextDueDate: reminder.nextDueDate,
            );

        await ref
            .read(reminderNotificationServiceProvider)
            .scheduleReminder(reminder);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.failedToSave}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime _computeInitialNextDueDate(ReminderData rd) {
    final now = DateTime.now();
    switch (rd.recurrence) {
      case ReminderRecurrence.daily:
        return DateTime(now.year, now.month, now.day + 1);
      case ReminderRecurrence.weekly:
        return DateTime(now.year, now.month, now.day + 7);
      case ReminderRecurrence.monthlyByDate:
        final d = rd.dayOfMonth ?? 1;
        var next = DateTime(now.year, now.month + 1, d);
        if (next.day != d) {
          next = DateTime(now.year, now.month + 2, 0);
        }
        return next;
      case ReminderRecurrence.customDays:
        return now.add(Duration(days: rd.customIntervalDays ?? 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;

    return Scaffold(
      appBar: AppBar(title: Text(s.addExpense)),
      body: ExpenseForm(
        onSave: _onSave,
        loading: _loading,
      ),
    );
  }
}
