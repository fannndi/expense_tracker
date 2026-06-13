import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../models/reminder.dart';
import '../../providers/reminder_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wallet_providers.dart';
import '../../utils/category_color.dart';
import '../../utils/constants.dart';
import '../../utils/currency_input_formatter.dart';
import '../../widgets/category_icon.dart';

class AddReminderScreen extends ConsumerStatefulWidget {
  final Reminder? initialReminder;

  const AddReminderScreen({super.key, this.initialReminder});

  @override
  ConsumerState<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends ConsumerState<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _customDaysCtrl;
  late String _selectedCategory;
  late ReminderRecurrence _recurrence;
  int _dayOfMonth = 1;
  String? _selectedWalletId;

  bool _loading = false;
  bool get _isEditing => widget.initialReminder != null;

  @override
  void initState() {
    super.initState();
    final r = widget.initialReminder;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _amountCtrl = TextEditingController(
      text: r != null && r.amount > 0
          ? ThousandSeparatorFormatter.addThousandSeparator(
              r.amount.toString())
          : '',
    );
    _noteCtrl = TextEditingController(text: r?.note ?? '');
    _customDaysCtrl = TextEditingController(
      text: r?.customIntervalDays?.toString() ?? '',
    );
    _selectedCategory = r?.category ?? AppStrings.categoryKeys.first;
    _recurrence = r?.recurrence ?? ReminderRecurrence.monthlyByDate;
    _dayOfMonth = r?.dayOfMonth ?? 27;
    _selectedWalletId = r?.walletId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _customDaysCtrl.dispose();
    super.dispose();
  }

  AppStrings _strings() {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    return AppStrings.forLocale(settings.locale);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final s = _strings();
    setState(() => _loading = true);

    try {
      final amount =
          ThousandSeparatorFormatter.parseFormatted(_amountCtrl.text.trim()) ??
              0;

      if (_isEditing) {
        final updated = widget.initialReminder!.copyWith(
          title: _titleCtrl.text.trim(),
          category: _selectedCategory,
          amount: amount,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          walletId: _selectedWalletId,
          recurrence: _recurrence,
          dayOfMonth: _recurrence == ReminderRecurrence.monthlyByDate
              ? _dayOfMonth
              : null,
          customIntervalDays: _recurrence == ReminderRecurrence.customDays
              ? int.tryParse(_customDaysCtrl.text)
              : null,
        );

        await ref.read(remindersProvider.notifier).updateReminder(updated);
        await ref
            .read(reminderNotificationServiceProvider)
            .rescheduleReminder(updated);
      } else {
        final nextDueDate = _computeInitialNextDueDate();
        final created = await ref
            .read(remindersProvider.notifier)
            .addReminder(
              title: _titleCtrl.text.trim(),
              category: _selectedCategory,
              amount: amount,
              note: _noteCtrl.text.trim().isEmpty
                  ? null
                  : _noteCtrl.text.trim(),
              walletId: _selectedWalletId,
              recurrence: _recurrence,
              dayOfMonth: _recurrence == ReminderRecurrence.monthlyByDate
                  ? _dayOfMonth
                  : null,
              customIntervalDays: _recurrence == ReminderRecurrence.customDays
                  ? int.tryParse(_customDaysCtrl.text)
                  : null,
              nextDueDate: nextDueDate,
            );

        await ref
            .read(reminderNotificationServiceProvider)
            .scheduleReminder(created);
      }

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

  DateTime _computeInitialNextDueDate() {
    final now = DateTime.now();
    switch (_recurrence) {
      case ReminderRecurrence.daily:
        return DateTime(now.year, now.month, now.day + 1);
      case ReminderRecurrence.weekly:
        return DateTime(now.year, now.month, now.day + 7);
      case ReminderRecurrence.monthlyByDate:
        final d = _dayOfMonth;
        var next = DateTime(now.year, now.month + 1, d);
        if (next.day != d) {
          next = DateTime(now.year, now.month + 2, 0);
        }
        return next;
      case ReminderRecurrence.customDays:
        final days = int.tryParse(_customDaysCtrl.text) ?? 30;
        return now.add(Duration(days: days));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _strings();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? s.editReminder : s.addReminder),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: s.reminderTitle,
                  hintText: 'e.g. Paket Data',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.title_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

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
                  final n =
                      ThousandSeparatorFormatter.parseFormatted(v.trim());
                  if (n == null) return s.enterValidNumber;
                  if (n <= 0) return s.amountGreaterThanZero;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: s.categoryLabel,
                  border: const OutlineInputBorder(),
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
              ),
              const SizedBox(height: 16),

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

              _buildWalletPicker(s),
              const SizedBox(height: 20),

              _buildRecurrenceSection(s, theme),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? s.save : s.addReminder),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletPicker(AppStrings s) {
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    return DropdownButtonFormField<String>(
      initialValue: _selectedWalletId,
      decoration: InputDecoration(
        labelText: s.payFrom,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
      ),
      isExpanded: true,
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text('-- ${s.all} --'),
        ),
        ...wallets.map((w) {
          final color = AppConstants.colorForWalletType(w.type);
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
                Expanded(child: Text(w.name)),
              ],
            ),
          );
        }),
      ],
      onChanged: (v) => setState(() => _selectedWalletId = v),
    );
  }

  Widget _buildRecurrenceSection(AppStrings s, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.reminderRecurrence,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReminderRecurrence>(
              initialValue: _recurrence,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
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
                if (v != null) setState(() => _recurrence = v);
              },
            ),
            if (_recurrence == ReminderRecurrence.monthlyByDate) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _dayOfMonth,
                decoration: InputDecoration(
                  labelText: s.dayOfMonth,
                  border: const OutlineInputBorder(),
                ),
                items: List.generate(31, (i) {
                  final day = i + 1;
                  return DropdownMenuItem(
                    value: day,
                    child: Text('$day'),
                  );
                }),
                onChanged: (v) {
                  if (v != null) setState(() => _dayOfMonth = v);
                },
              ),
            ],
            if (_recurrence == ReminderRecurrence.customDays) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customDaysCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: s.everyNDays,
                  hintText: '28',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Required';
                  }
                  final n = int.tryParse(v);
                  if (n == null || n < 1) return 'Min 1';
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
