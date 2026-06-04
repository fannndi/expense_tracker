import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_strings.dart';
import '../../../models/expense.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/category_color.dart';
import '../../../utils/currency_input_formatter.dart';
import '../../../utils/date_formatter.dart';
import '../../../widgets/category_icon.dart';

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
  /// Kalau true, amount 0 diperbolehkan (edit auto-fill entry)
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
    // Format amount dengan titik saat init (jika ada nilai awal)
    final initialAmount = e?.amount;
    _amountCtrl = TextEditingController(
      text: initialAmount != null && initialAmount > 0
          ? ThousandSeparatorFormatter.addThousandSeparator(
              initialAmount.toString())
          : '',
    );
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _selectedCategory = e?.category ?? AppStrings.categoryKeys.first;
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
    final amount =
        ThousandSeparatorFormatter.parseFormatted(_amountCtrl.text.trim()) ?? 0;
    await widget.onSave(
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
  }

  AppStrings _strings() {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    return AppStrings.forLocale(settings.locale);
  }

  @override
  Widget build(BuildContext context) {
    final s = _strings();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Amount field dengan auto-titik ──────────────────────────
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandSeparatorFormatter(),
              ],
              decoration: InputDecoration(
                labelText: s.amount,
                hintText: '15.000',
                prefixText: 'Rp ',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return s.amountRequired;
                final n = ThousandSeparatorFormatter.parseFormatted(v.trim());
                if (n == null) return s.enterValidNumber;
                if (!widget.allowZeroAmount && n <= 0) {
                  return s.amountGreaterThanZero;
                }
                if (n < 0) return s.amountNotNegative;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Category dropdown dengan icon ───────────────────────────
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: s.categoryLabel,
                border: const OutlineInputBorder(),
                // Icon kategori yang sedang dipilih ditampilkan di prefix
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: CategoryIcon(
                    category: _selectedCategory,
                    size: 32,
                  ),
                ),
              ),
              isExpanded: true,
              items: AppStrings.categoryKeys.map((key) {
                final color = CategoryColor.forCategory(key);
                return DropdownMenuItem<String>(
                  value: key,
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withAlpha(35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          CategoryIcon.iconFor(key),
                          color: color,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(s.categoryDisplayName(key)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategory = v);
              },
              validator: (v) =>
                  v == null || v.isEmpty ? s.categoryRequired : null,
            ),
            const SizedBox(height: 16),

            // ── Date picker ─────────────────────────────────────────────
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

            // ── Note ────────────────────────────────────────────────────
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
            OutlinedButton(
              onPressed:
                  widget.loading ? null : () => Navigator.of(context).pop(),
              child: Text(s.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
