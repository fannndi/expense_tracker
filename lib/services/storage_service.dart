import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/expense.dart';
import '../utils/constants.dart';

class StorageException implements Exception {
  final String message;
  final Object? cause;

  const StorageException(this.message, {this.cause});

  @override
  String toString() => 'StorageException: $message';
}

class StorageService {
  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${AppConstants.expensesFileName}');
  }

  Future<List<Expense>> loadExpenses() async {
    try {
      final file = await _getFile();

      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();

      if (content.trim().isEmpty) {
        return [];
      }

      final Map<String, dynamic> json = jsonDecode(content) as Map<String, dynamic>;
      final List<dynamic> rawList = json['expenses'] as List<dynamic>? ?? [];

      return rawList
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException catch (e) {
      throw StorageException('Data file is corrupted.', cause: e);
    } on IOException catch (e) {
      throw StorageException('Failed to read expense data.', cause: e);
    }
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    try {
      final file = await _getFile();
      final data = {
        'expenses': expenses.map((e) => e.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } on IOException catch (e) {
      throw StorageException('Failed to save expense data.', cause: e);
    }
  }
}
