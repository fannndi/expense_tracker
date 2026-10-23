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

  Future<File> _getTempFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${AppConstants.dataFileName}.import.tmp');
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
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return false;
      final data = decoded;

      if (!data.containsKey('expenses') &&
          !data.containsKey('incomes') &&
          !data.containsKey('wallets') &&
          !data.containsKey('reminders')) {
        return false;
      }

      final destFile = await _getDataFile();
      final tempFile = await _getTempFile();

      if (await destFile.exists()) {
        try {
          await destFile.copy('${destFile.path}.bak');
        } catch (_) {}
      }

      const encoder = JsonEncoder.withIndent('  ');
      await tempFile.writeAsString(encoder.convert(data));

      if (await destFile.exists()) {
        await destFile.delete();
      }
      await tempFile.rename(destFile.path);

      return true;
    } catch (e) {
      debugPrint('[Backup] Import failed: $e');
      return false;
    }
  }

  Future<void> shareExport() async {
    final path = await exportData();
    if (path != null) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: 'Expense Tracker Backup'),
      );
    }
  }
}
