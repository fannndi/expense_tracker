import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../providers/expense_providers.dart';
import '../../providers/settings_provider.dart';
import 'widgets/expense_form.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  bool _loading = false;

  Future<void> _onSave({
    required int amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final settings = ref.read(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;

    setState(() => _loading = true);
    try {
      await ref.read(expensesProvider.notifier).addExpense(
            amount: amount,
            category: category,
            date: date,
            note: note,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.failedToSave}: $e')),
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
      appBar: AppBar(title: Text(s.addExpense)),
      body: ExpenseForm(
        onSave: _onSave,
        loading: _loading,
      ),
    );
  }
}
