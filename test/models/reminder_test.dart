import 'package:flutter_test/flutter_test.dart';
import 'package:student_expense_tracker/models/reminder.dart';

void main() {
  group('Reminder nextDueFromDate', () {
    test('monthlyByDate handles month end', () {
      final r = Reminder(
        id: 'r1',
        title: 'Test',
        category: 'Other',
        amount: 1000,
        recurrence: ReminderRecurrence.monthlyByDate,
        dayOfMonth: 31,
        nextDueDate: DateTime(2025, 1, 31),
        createdAt: DateTime(2025, 1, 1),
        notificationId: 1,
      );
      final next = r.nextDueFromDate(DateTime(2025, 1, 31));
      // February has no 31st; should clamp to last day of February.
      expect(next.month, 2);
      expect(next.day, lessThanOrEqualTo(29));
    });

    test('customDays adds interval', () {
      final r = Reminder(
        id: 'r2',
        title: 'Test',
        category: 'Other',
        amount: 1000,
        recurrence: ReminderRecurrence.customDays,
        customIntervalDays: 10,
        nextDueDate: DateTime(2025, 1, 1),
        createdAt: DateTime(2025, 1, 1),
        notificationId: 2,
      );
      final next = r.nextDueFromDate(DateTime(2025, 1, 5));
      expect(next, DateTime(2025, 1, 15));
    });
  });
}
