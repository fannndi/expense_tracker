import '../models/reminder.dart';
import '../services/storage_service.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getAll();
  Future<void> add(Reminder reminder);
  Future<void> update(Reminder reminder);
  Future<void> delete(String id);
}

class LocalReminderRepository implements ReminderRepository {
  final StorageService _storageService;

  LocalReminderRepository(this._storageService);

  @override
  Future<List<Reminder>> getAll() => _storageService.loadReminders();

  @override
  Future<void> add(Reminder reminder) async {
    final reminders = await getAll();
    reminders.add(reminder);
    await _storageService.saveReminders(reminders);
  }

  @override
  Future<void> update(Reminder reminder) async {
    final reminders = await getAll();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index == -1) return;
    reminders[index] = reminder;
    await _storageService.saveReminders(reminders);
  }

  @override
  Future<void> delete(String id) async {
    final reminders = await getAll();
    reminders.removeWhere((r) => r.id == id);
    await _storageService.saveReminders(reminders);
  }
}
