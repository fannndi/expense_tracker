import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_strings.dart';
import '../../../models/expense.dart';
import '../../../models/reminder.dart';
import '../../../models/wallet.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/wallet_providers.dart';
import '../../../utils/category_color.dart';
import '../../../utils/constants.dart';
import '../../../utils/currency_input_formatter.dart';
import '../../../utils/date_formatter.dart';
import '../../../widgets/category_icon.dart';

typedef OnSaveCallback = Future<void> Function({
  required int amount,
  required String category,
  required DateTime date,
  String? note,
  String? walletId,
  bool isTransfer,
  ReminderData? reminderData,
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
  late final TextEditingController _customDaysCtrl;
  late String _selectedCategory;
  late DateTime _selectedDate;
  String? _selectedWalletId;
  bool _enableReminder = false;
  ReminderRecurrence _reminderRecurrence = ReminderRecurrence.monthlyByDate;
  int _reminderDayOfMonth = 27;

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
    _customDaysCtrl = TextEditingController();
    _selectedCategory = e?.category ?? AppStrings.categoryKeys.first;
    _selectedDate = e?.date ?? DateTime.now();
    _selectedWalletId = e?.walletId;

    // Default wallet: first cash wallet if none selected
    if (_selectedWalletId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final wallets = ref.read(walletsProvider).valueOrNull ?? [];
        final cashWallets =
            wallets.where((w) => w.type == WalletType.cash).toList();
        if (cashWallets.isNotEmpty && mounted) {
          setState(() => _selectedWalletId = cashWallets.first.id);
        }
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _customDaysCtrl.dispose();
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

  Widget _buildWalletPicker(AppStrings s) {
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];

    return DropdownButtonFormField<String>(
      initialValue: _selectedWalletId,
      decoration: InputDecoration(
        labelText: s.payFrom,
        border: const OutlineInputBorder(),
        prefixIcon: _selectedWalletId != null
            ? _buildWalletIcon(
                wallets.firstWhere(
                  (w) => w.id == _selectedWalletId,
                  orElse: () => wallets.first,
                ),
              )
            : const Icon(Icons.account_balance_wallet_outlined),
      ),
      isExpanded: true,
      items: wallets.map((w) {
        final color = AppConstants.colorForWalletType(w.type);
        final formatted = _formatBalance(w.balance);
        return DropdownMenuItem<String>(
          value: w.id,
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
                  AppConstants.iconForWalletType(w.type),
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  w.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatted,
                style: TextStyle(
                  color: w.balance >= 0 ? null : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedWalletId = v),
    );
  }

  String _formatBalance(int balance) {
    final isNegative = balance < 0;
    final abs = isNegative ? -balance : balance;
    final formatted = abs.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp ${isNegative ? '-' : ''}$formatted';
  }

  Widget _buildWalletIcon(Wallet wallet) {
    final color = AppConstants.colorForWalletType(wallet.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Icon(
        AppConstants.iconForWalletType(wallet.type),
        color: color,
      ),
    );
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
      walletId: _selectedWalletId,
      isTransfer: false,
      reminderData: _enableReminder
          ? ReminderData(
              recurrence: _reminderRecurrence,
              dayOfMonth: _reminderRecurrence == ReminderRecurrence.monthlyByDate
                  ? _reminderDayOfMonth
                  : null,
              customIntervalDays: _reminderRecurrence == ReminderRecurrence.customDays
                  ? int.tryParse(_customDaysCtrl.text)
                  : null,
            )
          : null,
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

            // ── Wallet picker (Pay from) ─────────────────────────────────
            _buildWalletPicker(s),
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
            const SizedBox(height: 16),

            // ── Reminder section ─────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_outlined,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          s.setReminder,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _enableReminder,
                          onChanged: (v) =>
                              setState(() => _enableReminder = v),
                        ),
                      ],
                    ),
                    if (_enableReminder) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ReminderRecurrence>(
                        initialValue: _reminderRecurrence,
                        decoration: InputDecoration(
                          labelText: s.reminderRecurrence,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: ReminderRecurrence.daily,
                            child: Text(s.daily),
                          ),
                          DropdownMenuItem(
                            value: ReminderRecurrence.weekly,
                            child: Text(s.weekly),
                          ),
                          DropdownMenuItem(
                            value: ReminderRecurrence.monthlyByDate,
                            child: Text(s.monthly),
                          ),
                          DropdownMenuItem(
                            value: ReminderRecurrence.customDays,
                            child: Text(s.customDays),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _reminderRecurrence = v);
                          }
                        },
                      ),
                      if (_reminderRecurrence ==
                          ReminderRecurrence.monthlyByDate) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _reminderDayOfMonth,
                          decoration: InputDecoration(
                            labelText: s.dayOfMonth,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: List.generate(31, (i) {
                            final day = i + 1;
                            return DropdownMenuItem(
                              value: day,
                              child: Text('$day'),
                            );
                          }),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _reminderDayOfMonth = v);
                            }
                          },
                        ),
                      ],
                      if (_reminderRecurrence ==
                          ReminderRecurrence.customDays) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _customDaysCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: s.everyNDays,
                            hintText: '28',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (v) {
                            if (!_enableReminder) {
                              return null;
                            }
                            if (_reminderRecurrence !=
                                ReminderRecurrence.customDays) {
                              return null;
                            }
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            final n = int.tryParse(v);
                            if (n == null || n < 1) {
                              return 'Min 1';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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
