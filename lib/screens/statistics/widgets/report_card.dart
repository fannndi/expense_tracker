import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_strings.dart';
import '../../../models/category_summary.dart';
import '../../../models/expense.dart';
import '../../../models/income.dart';
import '../../../providers/expense_providers.dart';
import '../../../providers/income_providers.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/report_service.dart';
import '../../../utils/date_formatter.dart';
import '../../../widgets/share_pdf_bottom_sheet.dart';

class ReportCard extends ConsumerWidget {
  final DateTime month;

  const ReportCard({super.key, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;

    final theme = Theme.of(context);
    final expenses = ref.watch(expensesProvider);
    final incomes = ref.watch(incomesProvider);
    final breakdown = ref.watch(
      categoryBreakdownForMonthProvider(
        (year: month.year, month: month.month),
      ),
    );

    final hasData = expenses.valueOrNull != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  s.monthlyReport,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.generateReportFor(DateFormatter.formatMonthYear(month)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share, size: 18),
                    label: Text(s.shareText),
                    onPressed: !hasData
                        ? null
                        : () => _shareText(
                              context,
                              expenses.valueOrNull!,
                              incomes.valueOrNull ?? [],
                              breakdown.valueOrNull ?? [],
                            ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: Text(s.sharePdf),
                    onPressed: !hasData
                        ? null
                        : () => SharePdfBottomSheet.show(context, ref),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ReportData _buildReportData(
    List<Expense> allExpenses,
    List<Income> allIncomes,
    List<CategorySummary> breakdown,
  ) {
    final filteredExpenses = allExpenses
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .toList();
    final filteredIncomes = allIncomes
        .where((i) => i.date.year == month.year && i.date.month == month.month)
        .toList();
    return ReportData(
      month: month,
      expenses: filteredExpenses,
      breakdown: breakdown,
      incomes: filteredIncomes,
    );
  }

  Future<void> _shareText(
    BuildContext context,
    List<Expense> expenses,
    List<Income> incomes,
    List<CategorySummary> breakdown,
  ) async {
    final data = _buildReportData(expenses, incomes, breakdown);
    final service = ReportService();
    final text = service.generateTextReport(data);
    await Share.share(
      text,
      subject: 'Expense Report - ${DateFormatter.formatMonthYear(month)}',
    );
  }
}
