import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_strings.dart';
import '../models/category_summary.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../providers/expense_providers.dart';
import '../providers/income_providers.dart';
import '../providers/settings_provider.dart';
import '../services/report_service.dart';

class SharePdfBottomSheet {
  SharePdfBottomSheet._();

  /// Shows the period-selector bottom sheet.
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _PeriodSelectorSheet(ref: ref),
    );
  }
}

class _PeriodSelectorSheet extends ConsumerWidget {
  final WidgetRef ref;
  const _PeriodSelectorSheet({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final settings = widgetRef.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;

    final now = DateTime.now();

    // ── Today ──────────────────────────────────────────────────────────────
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart;

    // ── This Week (Monday – Today) ─────────────────────────────────────────
    final daysFromMonday = now.weekday - DateTime.monday;
    final weekStart = DateTime(now.year, now.month, now.day - daysFromMonday);
    final weekEnd = todayStart;

    // ── This Month (1st – last day) ────────────────────────────────────────
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final monthFmt = DateFormat('MMMM', 'en_US');
    final monthName = monthFmt.format(now);
    final lastDay = monthEnd.day;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              s.sharePdfReport,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.today),
            title: Text(s.today),
            onTap: () {
              Navigator.of(context).pop();
              _generateAndSharePdf(context, ref, todayStart, todayEnd, s.today, s);
            },
          ),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(s.thisWeek),
            subtitle: Text(s.mondayToToday),
            onTap: () {
              Navigator.of(context).pop();
              _generateAndSharePdf(context, ref, weekStart, weekEnd, s.thisWeek, s);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(s.thisMonth),
            subtitle: Text('1 $monthName – $lastDay $monthName'),
            onTap: () {
              Navigator.of(context).pop();
              _generateAndSharePdf(context, ref, monthStart, monthEnd, monthName, s);
            },
          ),
          ListTile(
            leading: const Icon(Icons.savings_outlined),
            title: Text(s.allowancePeriod),
            onTap: () {
              Navigator.of(context).pop();
              _showAllowancePicker(context, ref, s);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _showAllowancePicker(
      BuildContext context, WidgetRef ref, AppStrings s) async {
    final periods = ref.read(allowancePeriodsProvider);

    if (periods.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.noAllowanceRecords)),
        );
      }
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  s.selectAllowancePeriod,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: periods.length,
                  itemBuilder: (_, i) {
                    final p = periods[i];
                    return ListTile(
                      leading: const Icon(Icons.savings_outlined),
                      title: Text(p.label),
                      subtitle: Text(p.rangeLabel),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _generateAndSharePdf(
                            context, ref, p.start, p.end, p.label, s);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// Filters data by [start]..[end], builds [ReportData], generates PDF,
/// and shares it via [Share.shareXFiles].
Future<void> _generateAndSharePdf(
  BuildContext context,
  WidgetRef ref,
  DateTime start,
  DateTime end,
  String label,
  AppStrings s,
) async {
  if (!context.mounted) return;

  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Text(s.generatingPdf),
        ],
      ),
    ),
  );

  try {
    final allExpenses =
        ref.read(expensesProvider).valueOrNull ?? <Expense>[];
    final allIncomes =
        ref.read(incomesProvider).valueOrNull ?? <Income>[];

    // Filter by date range (compare date-only, time-stripped)
    bool inRange(DateTime date) {
      final d = DateTime(date.year, date.month, date.day);
      return !d.isBefore(start) && !d.isAfter(end);
    }

    final filteredExpenses =
        allExpenses.where((e) => inRange(e.date)).toList();
    final filteredIncomes =
        allIncomes.where((i) => inRange(i.date)).toList();

    // Compute category breakdown from filtered expenses
    final breakdown = _buildBreakdown(filteredExpenses);

    final data = ReportData(
      month: start,
      expenses: filteredExpenses,
      breakdown: breakdown,
      incomes: filteredIncomes,
      periodLabel: label,
      periodStart: start,
      periodEnd: end,
    );

    final service = ReportService();
    final pdfBytes = await service.generatePdfReport(data);

    final dir = await getTemporaryDirectory();
    // Convert label to a safe filename fragment
    final safeLabel = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+$'), '');
    final filename = 'expense_report_$safeLabel.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(pdfBytes);

    if (context.mounted) {
      Navigator.of(context).pop(); // dismiss loading
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Expense Report – $label',
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop(); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.failedToGeneratePdf}: $e')),
      );
    }
  }
}

List<CategorySummary> _buildBreakdown(List<Expense> expenses) {
  if (expenses.isEmpty) return [];
  final totals = <String, int>{};
  for (final e in expenses) {
    if (e.isAutoFill && e.amount == 0) continue;
    totals[e.category] = (totals[e.category] ?? 0) + e.amount;
  }
  if (totals.isEmpty) return [];
  final grandTotal = totals.values.fold(0, (a, b) => a + b);
  final summaries = totals.entries.map((entry) {
    return CategorySummary(
      category: entry.key,
      total: entry.value,
      percentage: grandTotal > 0 ? entry.value / grandTotal * 100 : 0,
    );
  }).toList()
    ..sort((a, b) => b.total.compareTo(a.total));
  return summaries;
}
