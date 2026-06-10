import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
  Completer<void>? _lock;
  bool _migrated = false;

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${AppConstants.dataFileName}');
  }

  Future<File> _getLegacyFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${AppConstants.legacyDataFileName}');
  }

  Future<File> _getBackupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${AppConstants.dataFileName}.bak');
  }

  Future<File> _getTempFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${AppConstants.dataFileName}.tmp');
  }

  Future<void> _ensureMigrated() async {
    if (_migrated) return;
    _migrated = true;
    final file = await _getFile();
    if (await file.exists()) return;
    final legacy = await _getLegacyFile();
    if (await legacy.exists()) {
      try {
        await legacy.rename(file.path);
        debugPrint('[Storage] Migrated legacy file to ${file.path}');
      } catch (_) {
        final content = await legacy.readAsString();
        await file.writeAsString(content);
        await legacy.delete();
      }
    }
  }

  Future<T> _synchronized<T>(Future<T> Function() fn) async {
    while (_lock != null) {
      await _lock!.future;
    }
    _lock = Completer<void>();
    try {
      return await fn();
    } finally {
      _lock!.complete();
      _lock = null;
    }
  }

  // ─── Expenses ──────────────────────────────────────────────────────────

  Future<List<Expense>> loadExpenses() async {
    return _synchronized(() async {
      await _ensureMigrated();
      try {
        final data = await _readData();
        final List<dynamic> rawList =
            data['expenses'] as List<dynamic>? ?? [];
        return rawList
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList();
      } on FormatException catch (e) {
        throw StorageException('Data file is corrupted.', cause: e);
      } on IOException catch (e) {
        throw StorageException('Failed to read expense data.', cause: e);
      }
    });
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    return _synchronized(() async {
      await _ensureMigrated();
      try {
        final data = await _readData();
        data['expenses'] = expenses.map((e) => e.toJson()).toList();
        data['version'] = AppConstants.dataVersion;
        await _writeDataAtomic(data);
      } on IOException catch (e) {
        throw StorageException('Failed to save expense data.', cause: e);
      }
    });
  }

  // ─── Incomes ───────────────────────────────────────────────────────────

  Future<List<Income>> loadIncomes() async {
    return _synchronized(() async {
      await _ensureMigrated();
      try {
        final data = await _readData();
        final List<dynamic> rawList =
            data['incomes'] as List<dynamic>? ?? [];
        return rawList
            .map((e) => Income.fromJson(e as Map<String, dynamic>))
            .toList();
      } on FormatException catch (e) {
        throw StorageException('Data file is corrupted.', cause: e);
      } on IOException catch (e) {
        throw StorageException('Failed to read income data.', cause: e);
      }
    });
  }

  Future<void> saveIncomes(List<Income> incomes) async {
    return _synchronized(() async {
      await _ensureMigrated();
      try {
        final data = await _readData();
        data['incomes'] = incomes.map((e) => e.toJson()).toList();
        data['version'] = AppConstants.dataVersion;
        await _writeDataAtomic(data);
      } on IOException catch (e) {
        throw StorageException('Failed to save income data.', cause: e);
      }
    });
  }

  // ─── Wallets ───────────────────────────────────────────────────────────

  Future<List<Wallet>> loadWallets() async {
    return _synchronized(() async {
      await _ensureMigrated();
      try {
        final data = await _readData();
        final List<dynamic> rawList =
            data['wallets'] as List<dynamic>? ?? [];
        return rawList
            .map((e) => Wallet.fromJson(e as Map<String, dynamic>))
            .toList();
      } on FormatException catch (e) {
        throw StorageException('Data file is corrupted.', cause: e);
      } on IOException catch (e) {
        throw StorageException('Failed to read wallet data.', cause: e);
      }
    });
  }

  Future<void> saveWallets(List<Wallet> wallets) async {
    return _synchronized(() async {
      await _ensureMigrated();
      try {
        final data = await _readData();
        data['wallets'] = wallets.map((e) => e.toJson()).toList();
        data['version'] = AppConstants.dataVersion;
        await _writeDataAtomic(data);
      } on IOException catch (e) {
        throw StorageException('Failed to save wallet data.', cause: e);
      }
    });
  }

  // ─── Internal ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _readData() async {
    final file = await _getFile();
    if (!await file.exists()) {
      final backup = await _getBackupFile();
      if (await backup.exists()) {
        try {
          final content = await backup.readAsString();
          if (content.trim().isNotEmpty) {
            debugPrint('[Storage] Restored from backup file');
            return jsonDecode(content) as Map<String, dynamic>;
          }
        } catch (_) {
          // backup also corrupt, return empty
        }
      }
      return {};
    }
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return {};
      return jsonDecode(content) as Map<String, dynamic>;
    } on FormatException {
      final backup = await _getBackupFile();
      if (await backup.exists()) {
        try {
          final content = await backup.readAsString();
          if (content.trim().isNotEmpty) {
            debugPrint('[Storage] Main file corrupt, restored from backup');
            await backup.copy(file.path);
            return jsonDecode(content) as Map<String, dynamic>;
          }
        } catch (_) {
          // backup also corrupt
        }
      }
      rethrow;
    }
  }

  Future<void> _writeDataAtomic(Map<String, dynamic> data) async {
    final file = await _getFile();
    final tempFile = await _getTempFile();
    final backupFile = await _getBackupFile();

    final encoded = const JsonEncoder.withIndent('  ').convert(data);

    await tempFile.writeAsString(encoded);

    if (await file.exists()) {
      await file.copy(backupFile.path);
    }

    await tempFile.rename(file.path);
  }
}
