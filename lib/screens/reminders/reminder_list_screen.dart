import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/reminder.dart';
import '../../providers/reminder_providers.dart';
import '../../providers/settings_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/category_color.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class ReminderListScreen extends ConsumerWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = AppStrings.forLocale(settings.locale);
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.reminders),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_reminder',
        onPressed: () => context.push(AppRoutes.addReminder),
        child: const Icon(Icons.add),
      ),
      body: remindersAsync.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 72,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(100),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.noReminders,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.addReminder),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(s.addReminder),
                    ),
                  ],
                ),
              ),
            );
          }

          // Sort: active first, then by nextDueDate
          final sorted = List<Reminder>.from(reminders);
          sorted.sort((a, b) {
            if (a.isActive != b.isActive) {
              return a.isActive ? -1 : 1;
            }
            return a.nextDueDate.compareTo(b.nextDueDate);
          });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final reminder = sorted[index];
              return _ReminderTile(reminder: reminder);
            },
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(remindersProvider.notifier).reload(),
        ),
      ),
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  final Reminder reminder;

  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = AppStrings.forLocale(settings.locale);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final catColor = CategoryColor.forCategory(reminder.category);

    final isOverdue = reminder.isActive && reminder.nextDueDate.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );

    return Card(
      color: reminder.isActive
          ? (isOverdue ? cs.errorContainer.withAlpha(60) : null)
          : cs.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(AppRoutes.addReminder, extra: reminder),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CategoryIcon.iconFor(reminder.category),
                  color: catColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          reminder.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: reminder.isActive
                                ? null
                                : cs.onSurfaceVariant,
                          ),
                        ),
                        if (!reminder.isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'OFF',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatter.format(reminder.amount)} • ${s.categoryDisplayName(reminder.category)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_recurrenceLabel(reminder, s)} • ${DateFormatter.formatDisplay(reminder.nextDueDate)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isOverdue ? cs.error : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) => _handleAction(
                    context, ref, s, action, reminder),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(reminder.isActive ? 'Disable' : 'Enable'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(s.delete,
                        style: TextStyle(color: cs.error)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _recurrenceLabel(Reminder r, AppStrings s) {
    switch (r.recurrence) {
      case ReminderRecurrence.daily:
        return s.daily;
      case ReminderRecurrence.weekly:
        return s.weekly;
      case ReminderRecurrence.monthlyByDate:
        return '${s.monthly} (${s.dayOfMonth} ${r.dayOfMonth})';
      case ReminderRecurrence.customDays:
        return '${s.customDays} (${s.everyNDays} ${r.customIntervalDays})';
    }
  }

  void _handleAction(BuildContext context, WidgetRef ref, AppStrings s,
      String action, Reminder reminder) async {
    if (action == 'toggle') {
      final updated = reminder.copyWith(isActive: !reminder.isActive);
      await ref.read(remindersProvider.notifier).updateReminder(updated);
      if (updated.isActive) {
        await ref
            .read(reminderNotificationServiceProvider)
            .scheduleReminder(updated);
      } else {
        await ref
            .read(reminderNotificationServiceProvider)
            .cancelReminder(reminder.notificationId);
      }
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.deleteReminder),
          content: Text(s.deleteReminderConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: Text(s.delete),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await ref.read(remindersProvider.notifier).deleteReminder(reminder.id);
        await ref
            .read(reminderNotificationServiceProvider)
            .cancelReminder(reminder.notificationId);
      }
    }
  }
}
