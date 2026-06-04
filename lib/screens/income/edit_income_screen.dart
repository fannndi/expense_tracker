import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/income.dart';
import '../../providers/income_providers.dart';
import 'widgets/income_form.dart';

class EditIncomeScreen extends ConsumerStatefulWidget {
  final Income income;

  const EditIncomeScreen({super.key, required this.income});

  @override
  ConsumerState<EditIncomeScreen> createState() => _EditIncomeScreenState();
}

class _EditIncomeScreenState extends ConsumerState<EditIncomeScreen> {
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
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Income'),
        content: const Text(
            'Are you sure you want to delete this income entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
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
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Income'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: 'Delete',
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
