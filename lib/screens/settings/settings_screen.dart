import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull ?? const AppSettings();
    final s = AppStrings.forLocale(settings.locale);

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        children: [
          _SectionHeader(label: s.appearance),
          _OptionTile(
            label: s.themeSystem,
            selected: settings.themeMode == ThemeMode.system,
            onTap: () =>
                ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.system),
          ),
          _OptionTile(
            label: s.themeLight,
            selected: settings.themeMode == ThemeMode.light,
            onTap: () =>
                ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.light),
          ),
          _OptionTile(
            label: s.themeDark,
            selected: settings.themeMode == ThemeMode.dark,
            onTap: () =>
                ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark),
          ),
          const Divider(height: 1),
          _SectionHeader(label: s.language),
          _OptionTile(
            label: s.languageEnglish,
            selected: settings.locale == const Locale('en'),
            onTap: () =>
                ref.read(settingsProvider.notifier).setLocale(const Locale('en')),
          ),
          _OptionTile(
            label: s.languageIndonesian,
            selected: settings.locale == const Locale('id'),
            onTap: () =>
                ref.read(settingsProvider.notifier).setLocale(const Locale('id')),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: selected
          ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
