import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../models/income.dart';
import '../../providers/income_providers.dart';
import '../../providers/settings_provider.dart';
import 'widgets/income_form.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  bool _loading = false;

  Future<void> _onSave({
    required int amount,
    required IncomeType type,
    required DateTime date,
    String? source,
    String? note,
    String? walletId,
  }) async {
    final settings = ref.read(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;

    setState(() => _loading = true);
    try {
      await ref.read(incomesProvider.notifier).addIncome(
            amount: amount,
            type: type,
            date: date,
            source: source,
            note: note,
            walletId: walletId,
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
      appBar: AppBar(title: Text(s.addIncome)),
      body: IncomeForm(onSave: _onSave, loading: _loading),
    );
  }
}
