import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_strings.dart';
import '../../../models/expense.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/date_formatter.dart';

typedef OnSaveCallback = Future<void> Function({
  required int amount,
  required String category,
  required DateTime date,
  String? note,
});

class ExpenseForm extends ConsumerStatefulWidget {
  final Expense? initialExpense;
  final OnSaveCallback onSave;
  final bool loading;
  /// If true, amount 0 is allowed (for editing auto-fill entries).
  final bool allowZeroAmount;

  const ExpenseForm({
    super.key,
    this.initialExpense,
    required this.onSave,
    this.loading = false,
    this.allowZeroAmount = false,
  });

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late String _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final e = widget.initialExpense;
    _amountCtrl = TextEditingController(
      text: e != null ? e.amount.toString() : '',
    );
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _selectedCategory = e?.category ?? AppConstants.categories.first;
    _selectedDate = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSave(
      amount: int.parse(_amountCtrl.text.trim()),
      category: _selectedCategory,
      date: _selectedDate,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;

    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount field
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: s.amount,
                hintText: s.amountHint,
                prefixText: 'Rp ',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return s.amountRequired;
                final n = int.tryParse(v.trim());
                if (n == null) return s.enterValidNumber;
                if (!widget.allowZeroAmount && n <= 0) {
                  return s.amountGreaterThanZero;
                }
                if (n < 0) return s.amountNotNegative;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: s.categoryLabel,
                border: const OutlineInputBorder(),
              ),
              items: AppConstants.categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategory = v);
              },
              validator: (v) =>
                  v == null || v.isEmpty ? s.categoryRequired : null,
            ),
            const SizedBox(height: 16),

            // Date picker
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: s.date,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  DateFormatter.formatDisplay(_selectedDate),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Note field (optional)
            TextFormField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: s.noteOptional,
                hintText: s.noteHint,
                border: const OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton(
              onPressed: widget.loading ? null : _submit,
              child: widget.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.save),
            ),
            const SizedBox(height: 12),

            // Cancel button
            OutlinedButton(
              onPressed: widget.loading
                  ? null
                  : () => Navigator.of(context).pop(),
              child: Text(s.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
