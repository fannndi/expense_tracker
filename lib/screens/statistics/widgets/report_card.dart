import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/category_summary.dart';
import '../../../models/expense.dart';
import '../../../models/income.dart';
import '../../../providers/expense_providers.dart';
import '../../../providers/income_providers.dart';
import '../../../services/report_service.dart';
import '../../../utils/date_formatter.dart';

class ReportCard extends ConsumerWidget {
  final DateTime month;

  const ReportCard({super.key, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  'Monthly Report',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Generate and share a report for ${DateFormatter.formatMonthYear(month)}',
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
                    label: const Text('Share Text'),
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
                    label: const Text('Share PDF'),
                    onPressed: !hasData
                        ? null
                        : () => _sharePdf(
                              context,
                              expenses.valueOrNull!,
                              incomes.valueOrNull ?? [],
                              breakdown.valueOrNull ?? [],
                            ),
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

  Future<void> _sharePdf(
    BuildContext context,
    List<Expense> expenses,
    List<Income> incomes,
    List<CategorySummary> breakdown,
  ) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating PDF...'),
          ],
        ),
      ),
    );

    try {
      final data = _buildReportData(expenses, incomes, breakdown);
      final service = ReportService();
      final pdfBytes = await service.generatePdfReport(data);

      final dir = await getTemporaryDirectory();
      final filename =
          'expense_report_${month.year}_${month.month.toString().padLeft(2, '0')}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(pdfBytes);

      if (context.mounted) {
        Navigator.of(context).pop();
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Expense Report - ${DateFormatter.formatMonthYear(month)}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }
}
