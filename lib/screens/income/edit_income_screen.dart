import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../models/income.dart';
import '../../providers/income_providers.dart';
import '../../providers/settings_provider.dart';
import 'widgets/income_form.dart';

class EditIncomeScreen extends ConsumerStatefulWidget {
  final Income income;

  const EditIncomeScreen({super.key, required this.income});

  @override
  ConsumerState<EditIncomeScreen> createState() => _EditIncomeScreenState();
}

class _EditIncomeScreenState extends ConsumerState<EditIncomeScreen> {
  bool _loading = false;

  AppStrings get _s {
    final settings = ref.read(settingsProvider).valueOrNull ?? const AppSettings();
    return settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;
  }

  Future<void> _onSave({
    required int amount,
    required IncomeType type,
    required DateTime date,
    String? source,
    String? note,
  }) async {
    final s = _s;
    setState(() => _loading = true);
    try {
      final updated = widget.income.copyWith(
        amount: amount,
        type: type,
        date: date,
        source: source,
        note: note,
        clearSource: source == null || source.isEmpty,
        clearNote: note == null || note.isEmpty,
      );
      await ref.read(incomesProvider.notifier).updateIncome(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.failedToUpdate}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onDelete() async {
    final s = _s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteIncome),
        content: Text(s.deleteIncomeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await ref.read(incomesProvider.notifier).deleteIncome(widget.income.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.failedToDelete}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.editIncome),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: s.delete,
            onPressed: _loading ? null : _onDelete,
          ),
        ],
      ),
      body: IncomeForm(
        initialIncome: widget.income,
        onSave: _onSave,
        loading: _loading,
      ),
    );
  }
}
