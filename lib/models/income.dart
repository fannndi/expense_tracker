import 'package:intl/intl.dart';

enum IncomeType {
  allowance,    // Uang saku bulanan dari orang tua
  fromPerson,   // Dari kakak/keluarga/teman
  project,      // Hasil project / freelance
  other;        // Lainnya

  String get label {
    switch (this) {
      case IncomeType.allowance:
        return 'Allowance';
      case IncomeType.fromPerson:
        return 'From Person';
      case IncomeType.project:
        return 'Project';
      case IncomeType.other:
        return 'Other';
    }
  }

  String get jsonKey {
    switch (this) {
      case IncomeType.allowance:
        return 'allowance';
      case IncomeType.fromPerson:
        return 'from_person';
      case IncomeType.project:
        return 'project';
      case IncomeType.other:
        return 'other';
    }
  }

  static IncomeType fromJson(String value) {
    switch (value) {
      case 'allowance':
        return IncomeType.allowance;
      case 'from_person':
        return IncomeType.fromPerson;
      case 'project':
        return IncomeType.project;
      default:
        return IncomeType.other;
    }
  }
}

class Income {
  final String id;
  final DateTime date;
  final IncomeType type;
  final int amount;
  final String? source; // e.g. "Kakak", "PT ABC"
  final String? note;

  const Income({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    this.source,
    this.note,
  });

  Income copyWith({
    String? id,
    DateTime? date,
    IncomeType? type,
    int? amount,
    String? source,
    String? note,
    bool clearSource = false,
    bool clearNote = false,
  }) {
    return Income(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      source: clearSource ? null : (source ?? this.source),
      note: clearNote ? null : (note ?? this.note),
    );
  }

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      type: IncomeType.fromJson(json['type'] as String),
      amount: json['amount'] as int,
      source: json['source'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(date.toUtc()),
      'type': type.jsonKey,
      'amount': amount,
      if (source != null && source!.isNotEmpty) 'source': source,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Income && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
