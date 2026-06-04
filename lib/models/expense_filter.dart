class ExpenseFilter {
  final int? year;
  final int? month;
  final String? category;
  final String? searchNote;

  const ExpenseFilter({
    this.year,
    this.month,
    this.category,
    this.searchNote,
  });

  ExpenseFilter copyWith({
    int? year,
    int? month,
    String? category,
    String? searchNote,
    bool clearCategory = false,
    bool clearSearchNote = false,
  }) {
    return ExpenseFilter(
      year: year ?? this.year,
      month: month ?? this.month,
      category: clearCategory ? null : (category ?? this.category),
      searchNote: clearSearchNote ? null : (searchNote ?? this.searchNote),
    );
  }

  bool get hasActiveFilter =>
      category != null ||
      (searchNote != null && searchNote!.isNotEmpty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseFilter &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          category == other.category &&
          searchNote == other.searchNote;

  @override
  int get hashCode =>
      year.hashCode ^
      month.hashCode ^
      category.hashCode ^
      searchNote.hashCode;
}
