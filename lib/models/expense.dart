import 'package:intl/intl.dart';

class Expense {
  final String id;
  final DateTime date;
  final String category;
  final int amount;
  final String? note;

  const Expense({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    this.note,
  });

  Expense copyWith({
    String? id,
    DateTime? date,
    String? category,
    int? amount,
    String? note,
    bool clearNote = false,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: clearNote ? null : (note ?? this.note),
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      amount: json['amount'] as int,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(date.toUtc()),
      'category': category,
      'amount': amount,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Expense(id: $id, date: $date, category: $category, amount: $amount, note: $note)';
}
