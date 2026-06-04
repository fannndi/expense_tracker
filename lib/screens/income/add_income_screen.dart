import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/income.dart';
import '../../providers/income_providers.dart';
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
  }) async {
    setState(() => _loading = true);
    try {
      await ref.read(incomesProvider.notifier).addIncome(
            amount: amount,
            type: type,
            date: date,
            source: source,
            note: note,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Income')),
      body: IncomeForm(onSave: _onSave, loading: _loading),
    );
  }
}
