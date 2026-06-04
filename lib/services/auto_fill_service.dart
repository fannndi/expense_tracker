import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../utils/constants.dart';

/// Handles scheduling the 23:00 auto-fill reminder notification (Mon–Fri).
/// The actual data insertion is done in the app startup logic, not here.
/// This service only manages the notification that triggers/reminds the user.
class AutoFillNotificationService {
  static final AutoFillNotificationService _instance =
      AutoFillNotificationService._internal();
  factory AutoFillNotificationService() => _instance;
  AutoFillNotificationService._internal();

  static const _notificationId = 1001;
  static const _channelId = 'auto_fill_channel';
  static const _channelName = 'Auto-fill Reminder';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // App will handle auto-fill check on next foreground resume
  }

  /// Schedule daily notification at 23:00 for weekdays only.
  /// Called once at app start (or when user enables it).
  Future<void> scheduleDailyReminder() async {
    if (!_initialized) await init();

    // Cancel existing
    await _plugin.cancel(_notificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      AppConstants.autoFillHour,
      AppConstants.autoFillMinute,
    );

    // If already past 23:00 today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Skip weekends for first occurrence
    while (scheduled.weekday == DateTime.saturday ||
        scheduled.weekday == DateTime.sunday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _notificationId,
      'Expense Tracker',
      'Hari ini belum ada pengeluaran yang dicatat. Entry kosong akan ditambahkan.',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminder harian untuk mengisi pengeluaran',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint(
        '[AutoFill] Notification scheduled at ${AppConstants.autoFillHour}:${AppConstants.autoFillMinute.toString().padLeft(2, '0')}');
  }

  Future<void> cancelReminder() async {
    await _plugin.cancel(_notificationId);
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
}
