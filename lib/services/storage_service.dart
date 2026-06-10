import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/expense.dart';
import '../models/income.dart';
import '../models/wallet.dart';
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
    return File('${dir.path}/${AppConstants.dataFileName}');
  }

  // ─── Expenses ──────────────────────────────────────────────────────────

  Future<List<Expense>> loadExpenses() async {
    try {
      final data = await _readData();
      final List<dynamic> rawList = data['expenses'] as List<dynamic>? ?? [];
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
      final data = await _readData();
      data['expenses'] = expenses.map((e) => e.toJson()).toList();
      await _writeData(data);
    } on IOException catch (e) {
      throw StorageException('Failed to save expense data.', cause: e);
    }
  }

  // ─── Incomes ───────────────────────────────────────────────────────────

  Future<List<Income>> loadIncomes() async {
    try {
      final data = await _readData();
      final List<dynamic> rawList = data['incomes'] as List<dynamic>? ?? [];
      return rawList
          .map((e) => Income.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException catch (e) {
      throw StorageException('Data file is corrupted.', cause: e);
    } on IOException catch (e) {
      throw StorageException('Failed to read income data.', cause: e);
    }
  }

  Future<void> saveIncomes(List<Income> incomes) async {
    try {
      final data = await _readData();
      data['incomes'] = incomes.map((e) => e.toJson()).toList();
      await _writeData(data);
    } on IOException catch (e) {
      throw StorageException('Failed to save income data.', cause: e);
    }
  }

  // ─── Wallets ───────────────────────────────────────────────────────────

  Future<List<Wallet>> loadWallets() async {
    try {
      final data = await _readData();
      final List<dynamic> rawList = data['wallets'] as List<dynamic>? ?? [];
      return rawList
          .map((e) => Wallet.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException catch (e) {
      throw StorageException('Data file is corrupted.', cause: e);
    } on IOException catch (e) {
      throw StorageException('Failed to read wallet data.', cause: e);
    }
  }

  Future<void> saveWallets(List<Wallet> wallets) async {
    try {
      final data = await _readData();
      data['wallets'] = wallets.map((e) => e.toJson()).toList();
      await _writeData(data);
    } on IOException catch (e) {
      throw StorageException('Failed to save wallet data.', cause: e);
    }
  }

  // ─── Internal ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _readData() async {
    final file = await _getFile();
    if (!await file.exists()) return {};
    final content = await file.readAsString();
    if (content.trim().isEmpty) return {};
    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<void> _writeData(Map<String, dynamic> data) async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(data));
  }
}
