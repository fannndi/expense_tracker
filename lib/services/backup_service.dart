import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/constants.dart';

class BackupService {
  Future<File> _getDataFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${AppConstants.dataFileName}');
  }

  Future<String?> exportData() async {
    try {
      final file = await _getDataFile();
      if (!await file.exists()) return null;

      final dir = await getApplicationDocumentsDirectory();
      final exportFile = File('${dir.path}/expense_tracker_backup.json');
      await file.copy(exportFile.path);

      return exportFile.path;
    } catch (e) {
      debugPrint('[Backup] Export failed: $e');
      return null;
    }
  }

  Future<bool> importData(String filePath) async {
    try {
      final sourceFile = File(filePath);
      if (!await sourceFile.exists()) return false;

      final content = await sourceFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (!data.containsKey('expenses') &&
          !data.containsKey('incomes') &&
          !data.containsKey('wallets')) {
        return false;
      }

      final destFile = await _getDataFile();
      const encoder = JsonEncoder.withIndent('  ');
      await destFile.writeAsString(encoder.convert(data));

      return true;
    } catch (e) {
      debugPrint('[Backup] Import failed: $e');
      return false;
    }
  }

  Future<void> shareExport() async {
    final path = await exportData();
    if (path != null) {
      await Share.share('Expense Tracker Backup: $path');
    }
  }
}
