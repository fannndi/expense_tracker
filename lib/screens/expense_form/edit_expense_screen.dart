import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../models/expense.dart';
import '../../providers/expense_providers.dart';
import '../../providers/settings_provider.dart';
import 'widgets/expense_form.dart';

class EditExpenseScreen extends ConsumerStatefulWidget {
  final Expense expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  ConsumerState<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends ConsumerState<EditExpenseScreen> {
  bool _loading = false;

  AppStrings get _s {
    final settings = ref.read(settingsProvider).valueOrNull ?? const AppSettings();
    return settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;
  }

  Future<void> _onSave({
    required int amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final s = _s;
    setState(() => _loading = true);
    try {
      final updated = widget.expense.copyWith(
        amount: amount,
        category: category,
        date: date,
        note: note,
        clearNote: note == null || note.isEmpty,
      );
      await ref.read(expensesProvider.notifier).updateExpense(updated);
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
        title: Text(s.deleteExpense),
        content: Text(s.deleteExpenseConfirm),
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
      await ref
          .read(expensesProvider.notifier)
          .deleteExpense(widget.expense.id);
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
        title: Text(s.editExpense),
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
      body: Column(
        children: [
          // Banner for auto-fill entries
          if (widget.expense.isAutoFill)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.autoFillBanner,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onTertiaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ExpenseForm(
              initialExpense: widget.expense,
              onSave: _onSave,
              loading: _loading,
              allowZeroAmount: widget.expense.isAutoFill,
            ),
          ),
        ],
      ),
    );
  }
}
