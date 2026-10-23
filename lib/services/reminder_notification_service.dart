import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';

class ReminderNotificationService {
  static const _channelId = 'reminder_channel';
  static const _channelName = 'Payment Reminders';
  static const _notificationHour = 12;
  static const _notificationMinute = 0;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: settings);

    _initialized = true;
  }

  /// Schedule notification for a reminder at its nextDueDate, 12:00
  Future<void> scheduleReminder(Reminder reminder) async {
    if (!_initialized) await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      reminder.nextDueDate.year,
      reminder.nextDueDate.month,
      reminder.nextDueDate.day,
      _notificationHour,
      _notificationMinute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = now.add(const Duration(minutes: 1));
    }

    final formattedAmount =
        _formatAmount(reminder.amount);

    await _plugin.zonedSchedule(
      id: reminder.notificationId,
      title: '${reminder.title} — Rp $formattedAmount',
      body: 'Jatuh tempo hari ini. Ketuk untuk mencatat pembayaran.',
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Pengingat pembayaran berulang',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );

    debugPrint(
        '[ReminderNotif] Scheduled: ${reminder.id} → ${scheduled.day}/${scheduled.month}/${scheduled.year} 12:00');
  }

  Future<void> cancelReminder(int notificationId) async {
    await _plugin.cancel(id: notificationId);
  }

  Future<void> rescheduleReminder(Reminder reminder) async {
    await cancelReminder(reminder.notificationId);
    await scheduleReminder(reminder);
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return amount.toString();
  }
}
