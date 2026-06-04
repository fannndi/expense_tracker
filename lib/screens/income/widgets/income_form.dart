import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_strings.dart';
import '../../../models/income.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/currency_input_formatter.dart';
import '../../../utils/date_formatter.dart';

typedef OnIncomeCallback = Future<void> Function({
  required int amount,
  required IncomeType type,
  required DateTime date,
  String? source,
  String? note,
});

class IncomeForm extends ConsumerStatefulWidget {
  final Income? initialIncome;
  final OnIncomeCallback onSave;
  final bool loading;

  const IncomeForm({
    super.key,
    this.initialIncome,
    required this.onSave,
    this.loading = false,
  });

  @override
  ConsumerState<IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends ConsumerState<IncomeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _sourceCtrl;
  late final TextEditingController _noteCtrl;
  late IncomeType _selectedType;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final i = widget.initialIncome;
    final initialAmount = i?.amount;
    _amountCtrl = TextEditingController(
      text: initialAmount != null && initialAmount > 0
          ? ThousandSeparatorFormatter.addThousandSeparator(
              initialAmount.toString())
          : '',
    );
    _sourceCtrl = TextEditingController(text: i?.source ?? '');
    _noteCtrl = TextEditingController(text: i?.note ?? '');
    _selectedType = i?.type ?? IncomeType.allowance;
    _selectedDate = i?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _sourceCtrl.dispose();
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
      type: _selectedType,
      date: _selectedDate,
      source: _sourceCtrl.text.trim().isEmpty ? null : _sourceCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
  }

  AppStrings _s() {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    return AppStrings.forLocale(settings.locale);
  }

  @override
  Widget build(BuildContext context) {
    final s = _s();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Income type dengan icon ─────────────────────────────────
            DropdownButtonFormField<IncomeType>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: s.incomeType,
                border: const OutlineInputBorder(),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    _iconFor(_selectedType),
                    color: _colorFor(_selectedType),
                    size: 22,
                  ),
                ),
              ),
              isExpanded: true,
              items: IncomeType.values.map((t) {
                final color = _colorFor(t);
                return DropdownMenuItem<IncomeType>(
                  value: t,
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_iconFor(t), color: color, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(_localizedLabel(t, s)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),
            const SizedBox(height: 16),

            // ── Amount dengan auto-titik ────────────────────────────────
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandSeparatorFormatter(),
              ],
              decoration: InputDecoration(
                labelText: s.amount,
                hintText: '500.000',
                prefixText: 'Rp ',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return s.amountRequired;
                final n =
                    ThousandSeparatorFormatter.parseFormatted(v.trim());
                if (n == null) return s.enterValidNumber;
                if (n <= 0) return s.amountGreaterThanZero;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Source ─────────────────────────────────────────────────
            TextFormField(
              controller: _sourceCtrl,
              decoration: InputDecoration(
                labelText: s.sourceOptional,
                hintText: _sourcePlaceholder(_selectedType, s),
                border: const OutlineInputBorder(),
              ),
              maxLength: 60,
            ),
            const SizedBox(height: 8),

            // ── Date ───────────────────────────────────────────────────
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

            // ── Note ───────────────────────────────────────────────────
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

  static IconData _iconFor(IncomeType type) {
    switch (type) {
      case IncomeType.allowance:
        return Icons.home_rounded;
      case IncomeType.fromPerson:
        return Icons.person_rounded;
      case IncomeType.project:
        return Icons.work_rounded;
      case IncomeType.other:
        return Icons.category_rounded;
    }
  }

  static Color _colorFor(IncomeType type) {
    switch (type) {
      case IncomeType.allowance:
        return const Color(0xFF1565C0);
      case IncomeType.fromPerson:
        return const Color(0xFF2E7D32);
      case IncomeType.project:
        return const Color(0xFFE65100);
      case IncomeType.other:
        return const Color(0xFF6A1B9A);
    }
  }

  static String _localizedLabel(IncomeType type, AppStrings s) {
    switch (type) {
      case IncomeType.allowance:
        return s.incomeTypeAllowance;
      case IncomeType.fromPerson:
        return s.incomeTypeFromPerson;
      case IncomeType.project:
        return s.incomeTypeProject;
      case IncomeType.other:
        return s.incomeTypeOther;
    }
  }

  static String _sourcePlaceholder(IncomeType type, AppStrings s) {
    switch (type) {
      case IncomeType.allowance:
        return 'Papa, Mama';
      case IncomeType.fromPerson:
        return s.locale == 'id' ? 'Kakak, Om Budi' : 'Brother, Uncle Budi';
      case IncomeType.project:
        return s.locale == 'id' ? 'Proyek website PT ABC' : 'Website project ABC';
      case IncomeType.other:
        return s.locale == 'id' ? 'Bonus, Hadiah' : 'Bonus, Gift';
    }
  }
}

extension on AppStrings {
  // helper kecil buat cek locale tanpa import flutter
  String get locale => this == AppStrings.id ? 'id' : 'en';
}
