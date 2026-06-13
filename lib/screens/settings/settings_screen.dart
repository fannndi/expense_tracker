import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../providers/settings_provider.dart';
import '../../routes/app_router.dart';
import '../../services/backup_service.dart';

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
          const Divider(height: 1),
          _SectionHeader(label: s.exportData),
          ListTile(
            leading: Icon(Icons.upload_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(s.exportData, style: Theme.of(context).textTheme.bodyLarge),
            onTap: () async {
              await BackupService().shareExport();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.dataExported)),
                );
              }
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          ListTile(
            leading: Icon(Icons.download_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(s.importData, style: Theme.of(context).textTheme.bodyLarge),
            onTap: () => _showImportDialog(context, ref, s),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          const Divider(height: 1),
          _SectionHeader(label: s.reminders),
          ListTile(
            leading: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(s.reminders, style: Theme.of(context).textTheme.bodyLarge),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.reminders),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          const Divider(height: 1),
          _SectionHeader(label: s.about),
          const _AboutTile(),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref, AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.importData),
        content: Text(s.importDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Import would require file picker - placeholder for now
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.importData)),
              );
            },
            child: Text(s.importData),
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

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Expense Tracker',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'v1.0.0+1',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A personal expense tracker for university students.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
