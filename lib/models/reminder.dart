import 'package:intl/intl.dart';

enum ReminderRecurrence { daily, weekly, monthlyByDate, customDays }

class ReminderData {
  final ReminderRecurrence recurrence;
  final int? dayOfMonth;
  final int? customIntervalDays;

  const ReminderData({
    required this.recurrence,
    this.dayOfMonth,
    this.customIntervalDays,
  });
}

class Reminder {
  final String id;
  final String title;
  final String category;
  final int amount;
  final String? note;
  final String? walletId;
  final ReminderRecurrence recurrence;
  final int? dayOfMonth;
  final int? customIntervalDays;
  final DateTime nextDueDate;
  final bool isActive;
  final DateTime createdAt;
  final int notificationId;

  const Reminder({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    this.note,
    this.walletId,
    required this.recurrence,
    this.dayOfMonth,
    this.customIntervalDays,
    required this.nextDueDate,
    this.isActive = true,
    required this.createdAt,
    required this.notificationId,
  });

  static int _stableHash(String id) {
    int h = 0;
    for (int i = 0; i < id.length; i++) {
      h = 31 * h + id.codeUnitAt(i);
      h &= 0x7FFFFFFF;
    }
    return h;
  }

  static int notificationIdFor(String id) => 10000 + (_stableHash(id) % 900000);

  DateTime nextDueFromToday() {
    final now = DateTime.now();
    switch (recurrence) {
      case ReminderRecurrence.daily:
        return DateTime(now.year, now.month, now.day + 1);
      case ReminderRecurrence.weekly:
        return DateTime(now.year, now.month, now.day + 7);
      case ReminderRecurrence.monthlyByDate:
        final d = dayOfMonth ?? 1;
        var next = DateTime(now.year, now.month + 1, d);
        if (next.day != d) {
          next = DateTime(now.year, now.month + 2, 0);
        }
        return next;
      case ReminderRecurrence.customDays:
        return now.add(Duration(days: customIntervalDays ?? 30));
    }
  }

  DateTime nextDueFromDate(DateTime from) {
    switch (recurrence) {
      case ReminderRecurrence.daily:
        return DateTime(from.year, from.month, from.day + 1);
      case ReminderRecurrence.weekly:
        return DateTime(from.year, from.month, from.day + 7);
      case ReminderRecurrence.monthlyByDate:
        final d = dayOfMonth ?? 1;
        var next = DateTime(from.year, from.month + 1, d);
        if (next.day != d) {
          next = DateTime(from.year, from.month + 2, 0);
        }
        return next;
      case ReminderRecurrence.customDays:
        return from.add(Duration(days: customIntervalDays ?? 30));
    }
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? category,
    int? amount,
    String? note,
    String? walletId,
    ReminderRecurrence? recurrence,
    int? dayOfMonth,
    int? customIntervalDays,
    DateTime? nextDueDate,
    bool? isActive,
    DateTime? createdAt,
    int? notificationId,
    bool clearNote = false,
    bool clearWalletId = false,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: clearNote ? null : (note ?? this.note),
      walletId: clearWalletId ? null : (walletId ?? this.walletId),
      recurrence: recurrence ?? this.recurrence,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      customIntervalDays: customIntervalDays ?? this.customIntervalDays,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return Reminder(
      id: id,
      title: json['title'] as String,
      category: json['category'] as String,
      amount: json['amount'] as int,
      note: json['note'] as String?,
      walletId: json['walletId'] as String?,
      recurrence: ReminderRecurrence.values.firstWhere(
        (e) => e.name == json['recurrence'],
        orElse: () => ReminderRecurrence.daily,
      ),
      dayOfMonth: json['dayOfMonth'] as int?,
      customIntervalDays: json['customIntervalDays'] as int?,
      nextDueDate: DateTime.parse(json['nextDueDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notificationId: json['notificationId'] as int? ?? notificationIdFor(id),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      if (note != null && note!.isNotEmpty) 'note': note,
      if (walletId != null) 'walletId': walletId,
      'recurrence': recurrence.name,
      if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
      if (customIntervalDays != null) 'customIntervalDays': customIntervalDays,
      'nextDueDate': DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(nextDueDate.toUtc()),
      'isActive': isActive,
      'createdAt': DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(createdAt.toUtc()),
      'notificationId': notificationId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reminder &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Reminder(id: $id, title: $title, amount: $amount, recurrence: ${recurrence.name}, nextDueDate: $nextDueDate, isActive: $isActive)';
}
