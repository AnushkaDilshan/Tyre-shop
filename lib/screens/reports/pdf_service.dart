import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/report_provider.dart';
import '../../utils/app_helpers.dart';

class PdfService {
  static Future<void> generateAndShare({
    required ReportData reportData,
    required ReportType reportType,
    required DateTime reportDate,
  }) async {
    final pdf = pw.Document();
    final typeLabel = reportType.name[0].toUpperCase() + reportType.name.substring(1);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TYRE SHOP MANAGER',
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text('$typeLabel Report',
                        style: const pw.TextStyle(
                            fontSize: 12, color: PdfColors.grey)),
                  ],
                ),
                pw.Text(
                  'Generated: ${AppHelpers.formatDateTime(DateTime.now())}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.red),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (ctx) => [
          // Summary section
          pw.Text('Summary',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _tableHeaderRow(['Metric', 'Amount']),
              _tableRow(['Total Revenue',
                  AppHelpers.formatCurrency(reportData.totalRevenue)]),
              _tableRow(['Gross Profit',
                  AppHelpers.formatCurrency(reportData.totalProfit)]),
              _tableRow(['Total Expenses',
                  AppHelpers.formatCurrency(reportData.totalExpenses)]),
              _tableRow(['Net Profit',
                  AppHelpers.formatCurrency(reportData.netProfit)]),
              _tableRow(
                  ['Total Sales', '${reportData.totalSales}']),
            ],
          ),
          pw.SizedBox(height: 20),

          // Sales by category
          if (reportData.salesByCategory.isNotEmpty) ...[
            pw.Text('Sales by Category',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _tableHeaderRow(['Category', 'Revenue']),
                ...reportData.salesByCategory.entries
                    .map((e) => _tableRow([
                          e.key,
                          AppHelpers.formatCurrency(e.value),
                        ])),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Expenses by category
          if (reportData.expenseByCategory.isNotEmpty) ...[
            pw.Text('Expenses by Category',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _tableHeaderRow(['Category', 'Amount']),
                ...reportData.expenseByCategory.entries
                    .map((e) => _tableRow([
                          e.key,
                          AppHelpers.formatCurrency(e.value),
                        ])),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Individual sales
          if (reportData.sales.isNotEmpty) ...[
            pw.Text('Sales Records',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.5),
                4: pw.FlexColumnWidth(1),
              },
              children: [
                _tableHeaderRow([
                  'Date', 'Customer', 'Amount', 'Profit', 'Payment'
                ]),
                ...reportData.sales.map((s) => _tableRow([
                      AppHelpers.formatDateShort(s.date),
                      s.customerName ?? 'Walk-in',
                      AppHelpers.formatCurrency(s.netAmount),
                      AppHelpers.formatCurrency(s.totalProfit),
                      s.paymentMethod,
                    ])),
              ],
            ),
          ],
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'tyre_shop_${typeLabel.toLowerCase()}_report_${AppHelpers.formatDateShort(reportDate).replaceAll('/', '-')}.pdf',
    );
  }

  static pw.TableRow _tableHeaderRow(List<String> cells) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: cells
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(c,
                    style:
                        pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ))
          .toList(),
    );
  }

  static pw.TableRow _tableRow(List<String> cells) {
    return pw.TableRow(
      children: cells
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(c, style: const pw.TextStyle(fontSize: 10)),
              ))
          .toList(),
    );
  }
}