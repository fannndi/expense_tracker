// ─── Settings provider ───────────────────────────────────────────────────────
// This file is a stub created by this agent so that dependent files compile.
// Agent A will replace this with the full implementation (persistence via
// SharedPreferences, settings screen integration, etc.).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class AppSettings {
  final ThemeMode themeMode;
  final Locale locale;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
  });

  AppSettings copyWith({ThemeMode? themeMode, Locale? locale}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.index,
        'locale': locale.languageCode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
        locale: Locale(json['locale'] as String? ?? 'en'),
      );
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _fileName = 'settings.json';

  @override
  Future<AppSettings> build() async {
    return _load();
  }

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<AppSettings> _load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return const AppSettings();
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> _save(AppSettings s) async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(s.toJson()));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(themeMode: mode);
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> setLocale(Locale locale) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(locale: locale);
    state = AsyncData(updated);
    await _save(updated);
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
