import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/category_summary.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class ReportData {
  final DateTime month;
  final List<Expense> expenses;
  final List<CategorySummary> breakdown;
  final List<Income> incomes;
  final String periodLabel;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  const ReportData({
    required this.month,
    required this.expenses,
    required this.breakdown,
    this.incomes = const [],
    this.periodLabel = '',
    this.periodStart,
    this.periodEnd,
  });

  int get totalSpending =>
      expenses.where((e) => !e.isAutoFill || e.amount > 0).fold(
            0,
            (sum, e) => sum + e.amount,
          );
  int get totalIncome => incomes.fold(0, (sum, i) => sum + i.amount);
  int get netBalance => totalIncome - totalSpending;
  int get totalTransactions =>
      expenses.where((e) => !e.isAutoFill || e.amount > 0).length;
}

class ReportService {
  /// Generate plain text report
  String generateTextReport(ReportData data) {
    final buffer = StringBuffer();
    buffer.writeln('=== ${AppConstants.appName} ===');    buffer.writeln('Expense Report');
    buffer.writeln('Month: ${DateFormatter.formatMonthYear(data.month)}');
    buffer.writeln('Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}');
    buffer.writeln();
    buffer.writeln('─────────────────────────────');
    buffer.writeln('Total Income   : ${CurrencyFormatter.format(data.totalIncome)}');
    buffer.writeln('Total Spending : ${CurrencyFormatter.format(data.totalSpending)}');
    buffer.writeln('Net Balance    : ${data.netBalance >= 0 ? '+' : ''}${CurrencyFormatter.format(data.netBalance)}');
    buffer.writeln('Total Transactions: ${data.totalTransactions}');
    buffer.writeln();
    buffer.writeln('BREAKDOWN BY CATEGORY:');
    for (final s in data.breakdown) {
      buffer.writeln(
          '  ${s.category}: ${CurrencyFormatter.format(s.total)} (${s.percentage.toStringAsFixed(1)}%)');
    }
    buffer.writeln();
    buffer.writeln('TRANSACTION DETAILS:');
    buffer.writeln('─────────────────────────────');
    final sorted = List<Expense>.from(data.expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    for (final e in sorted) {
      // Skip auto-fill entries with 0 amount dalam teks report
      if (e.isAutoFill && e.amount == 0) continue;
      buffer.write('${DateFormatter.formatDisplay(e.date)} | ');
      buffer.write('${e.category} | ');
      buffer.write(CurrencyFormatter.format(e.amount));
      if (e.note != null && e.note!.isNotEmpty) {
        buffer.write(' | ${e.note}');
      }
      buffer.writeln();
    }
    buffer.writeln('─────────────────────────────');
    buffer.writeln(AppConstants.appName);
    return buffer.toString();
  }

  /// Generate PDF report
  Future<Uint8List> generatePdfReport(ReportData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(data),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildSummarySection(data),
          pw.SizedBox(height: 16),
          if (data.incomes.isNotEmpty) ...[
            _buildIncomeSection(data),
            pw.SizedBox(height: 16),
          ],
          _buildBreakdownSection(data),
          pw.SizedBox(height: 16),
          _buildTransactionsSection(data),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(ReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blueGrey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                AppConstants.appName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'Expense Report',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                data.periodLabel.isNotEmpty
                    ? data.periodLabel
                    : DateFormatter.formatMonthYear(data.month),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.blueGrey200, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            AppConstants.appName,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(ReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(
              'Total Income', CurrencyFormatter.format(data.totalIncome)),
          _summaryItem(
              'Total Spending', CurrencyFormatter.format(data.totalSpending)),
          _summaryItem(
              'Net Balance',
              '${data.netBalance >= 0 ? '+' : ''}${CurrencyFormatter.format(data.netBalance)}'),
          _summaryItem('Transactions', '${data.totalTransactions}'),
        ],
      ),
    );
  }

  pw.Widget _buildIncomeSection(ReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Income',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2.5),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.green50),
              children: [
                _tableHeader('Date'),
                _tableHeader('Type'),
                _tableHeader('Amount'),
                _tableHeader('Source / Note'),
              ],
            ),
            ...data.incomes.map(
              (i) => pw.TableRow(children: [
                _tableCell(DateFormatter.formatDisplay(i.date)),
                _tableCell(i.type.label),
                _tableCell(CurrencyFormatter.format(i.amount)),
                _tableCell(
                    [i.source, i.note].where((v) => v != null).join(' – ')),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _summaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _buildBreakdownSection(ReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Category Breakdown',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey300,
            width: 0.5,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
              children: [
                _tableHeader('Category'),
                _tableHeader('Amount'),
                _tableHeader('Percentage'),
              ],
            ),
            ...data.breakdown.map(
              (s) => pw.TableRow(
                children: [
                  _tableCell(s.category),
                  _tableCell(CurrencyFormatter.format(s.total)),
                  _tableCell('${s.percentage.toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTransactionsSection(ReportData data) {
    final sorted = List<Expense>.from(data.expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Transaction Details',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey300,
            width: 0.5,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2.5),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
              children: [
                _tableHeader('Date'),
                _tableHeader('Category'),
                _tableHeader('Amount'),
                _tableHeader('Note'),
              ],
            ),
            ...sorted.map(
              (e) => pw.TableRow(
                children: [
                  _tableCell(DateFormatter.formatDisplay(e.date)),
                  _tableCell(e.category),
                  _tableCell(CurrencyFormatter.format(e.amount)),
                  _tableCell(e.note ?? '-'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }
}
