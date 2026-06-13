import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/reminder.dart';
import '../repositories/reminder_repository.dart';
import '../services/reminder_notification_service.dart';
import 'expense_providers.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => LocalReminderRepository(ref.watch(storageServiceProvider)),
);

class RemindersNotifier extends AsyncNotifier<List<Reminder>> {
  @override
  Future<List<Reminder>> build() async {
    return ref.read(reminderRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(reminderRepositoryProvider).getAll(),
    );
  }

  Future<Reminder> addReminder({
    required String title,
    required String category,
    required int amount,
    String? note,
    String? walletId,
    required ReminderRecurrence recurrence,
    int? dayOfMonth,
    int? customIntervalDays,
    required DateTime nextDueDate,
  }) async {
    final id = 'rem_${const Uuid().v4()}';
    final reminder = Reminder(
      id: id,
      title: title,
      category: category,
      amount: amount,
      note: note,
      walletId: walletId,
      recurrence: recurrence,
      dayOfMonth: dayOfMonth,
      customIntervalDays: customIntervalDays,
      nextDueDate: nextDueDate,
      isActive: true,
      createdAt: DateTime.now(),
      notificationId: Reminder.notificationIdFor(id),
    );
    await ref.read(reminderRepositoryProvider).add(reminder);
    await reload();
    return reminder;
  }

  Future<void> updateReminder(Reminder reminder) async {
    await ref.read(reminderRepositoryProvider).update(reminder);
    await reload();
  }

  Future<void> deleteReminder(String id) async {
    await ref.read(reminderRepositoryProvider).delete(id);
    await reload();
  }

  Future<void> toggleActive(Reminder reminder) async {
    await updateReminder(reminder.copyWith(isActive: !reminder.isActive));
  }

  /// Cari reminder by ID dari state
  Reminder? findById(String id) {
    final list = state.valueOrNull;
    if (list == null) return null;
    try {
      return list.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}

final reminderNotificationServiceProvider =
    Provider<ReminderNotificationService>((ref) {
  return ReminderNotificationService();
});

final remindersProvider =
    AsyncNotifierProvider<RemindersNotifier, List<Reminder>>(
  RemindersNotifier.new,
);

/// Reminder yang sudah jatuh tempo (nextDueDate <= today) dan isActive
final dueRemindersProvider = Provider<AsyncValue<List<Reminder>>>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return ref.watch(remindersProvider).whenData((list) {
    return list
        .where((r) => r.isActive && !r.nextDueDate.isAfter(today))
        .toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  });
});
