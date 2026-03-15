import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/report_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_helpers.dart';
import 'pdf_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().generateReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              provider.generateReport();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Report refreshed!'),
                duration: Duration(seconds: 1),
                backgroundColor: AppTheme.successColor,
              ));
            },
          ),
          if (provider.reportData != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export PDF',
              onPressed: () => _exportPdf(context, provider),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _pickDate(context, provider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _ReportTypeSelector(provider: provider),
        ),
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor))
          : provider.reportData == null
              ? const Center(
                  child: Text('No data available',
                      style: TextStyle(color: AppTheme.textMuted)))
              : _ReportBody(provider: provider),
    );
  }

  Future<void> _pickDate(BuildContext context, ReportProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.reportDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.accentColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) provider.setReportDate(picked);
  }

  Future<void> _exportPdf(BuildContext ctx, ReportProvider provider) async {
    try {
      await PdfService.generateAndShare(
        reportData: provider.reportData!,
        reportType: provider.reportType,
        reportDate: provider.reportDate,
      );
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text('PDF error: $e'),
            backgroundColor: AppTheme.errorColor));
      }
    }
  }
}

class _ReportTypeSelector extends StatelessWidget {
  final ReportProvider provider;
  const _ReportTypeSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ReportType.values.map((t) {
          final label = t.name[0].toUpperCase() + t.name.substring(1);
          final selected = provider.reportType == t;
          return GestureDetector(
            onTap: () => provider.setReportType(t),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.accentColor
                    : AppTheme.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : AppTheme.textMuted,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final ReportProvider provider;
  const _ReportBody({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = provider.reportData!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period label
        Center(
          child: Text(
            _periodLabel(provider),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),

        // Summary cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _SummaryCard(
              label: 'Revenue',
              value: AppHelpers.formatCurrency(data.totalRevenue),
              color: AppTheme.successColor,
              icon: Icons.attach_money,
            ),
            _SummaryCard(
              label: 'Gross Profit',
              value: AppHelpers.formatCurrency(data.totalProfit),
              color: AppTheme.accentColor,
              icon: Icons.trending_up,
            ),
            _SummaryCard(
              label: 'Expenses',
              value: AppHelpers.formatCurrency(data.totalExpenses),
              color: AppTheme.warningColor,
              icon: Icons.money_off,
            ),
            _SummaryCard(
              label: 'Net Profit',
              value: AppHelpers.formatCurrency(data.netProfit),
              color: data.netProfit >= 0
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
              icon: data.netProfit >= 0
                  ? Icons.sentiment_satisfied
                  : Icons.sentiment_dissatisfied,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Total sales count
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Sales Transactions',
                  style: TextStyle(color: AppTheme.textMuted)),
              Text('${data.totalSales}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Revenue trend chart
        if (data.dailyRevenue.isNotEmpty) ...[
          _SectionHeader('Revenue Trend'),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: _RevenueTrendChart(data: data.dailyRevenue),
          ),
          const SizedBox(height: 24),
        ],

        // Sales by category pie
        if (data.salesByCategory.isNotEmpty) ...[
          _SectionHeader('Sales by Category'),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _CategoryPieChart(
                dataMap: data.salesByCategory, colors: _pieColors),
          ),
          ..._legend(data.salesByCategory, _pieColors),
          const SizedBox(height: 24),
        ],

        // Expenses by category
        if (data.expenseByCategory.isNotEmpty) ...[
          _SectionHeader('Expenses by Category'),
          const SizedBox(height: 12),
          ...data.expenseByCategory.entries.map((e) => _BarRow(
                label: e.key,
                value: (e.value as num).toDouble(),
                max: data.totalExpenses,
                color: AppTheme.warningColor,
              )),
          const SizedBox(height: 24),
        ],

        // Sales list
        if (data.sales.isNotEmpty) ...[
          _SectionHeader('Sale Records'),
          const SizedBox(height: 12),
          ...data.sales.take(10).map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.customerName ?? 'Walk-in',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13)),
                          Text(AppHelpers.formatDateTime(s.date),
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(AppHelpers.formatCurrency(s.netAmount),
                            style: const TextStyle(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w600)),
                        Text(
                            'Profit: ${AppHelpers.formatCurrency(s.totalProfit)}',
                            style: const TextStyle(
                                color: AppTheme.accentColor, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              )),
          if (data.sales.length > 10)
            Center(
              child: Text('+ ${data.sales.length - 10} more sales',
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  String _periodLabel(ReportProvider p) {
    switch (p.reportType) {
      case ReportType.daily:
        return AppHelpers.formatDate(p.reportDate);
      case ReportType.weekly:
        final start =
            p.reportDate.subtract(Duration(days: p.reportDate.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return '${AppHelpers.formatDate(start)} – ${AppHelpers.formatDate(end)}';
      case ReportType.monthly:
        return '${_monthName(p.reportDate.month)} ${p.reportDate.year}';
    }
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month];
  }

  List<Color> get _pieColors => [
        AppTheme.accentColor,
        const Color(0xFF7C4DFF),
        const Color(0xFF00BCD4),
        AppTheme.successColor,
        AppTheme.warningColor,
        const Color(0xFFFF5722),
      ];

  List<Widget> _legend(Map<String, double> map, List<Color> colors) {
    final entries = map.entries.toList();
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final color = colors[index % colors.length];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(entry.key,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12))),
            Text(AppHelpers.formatCurrency(entry.value),
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    });
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _RevenueTrendChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  const _RevenueTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();
    final maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.white10, strokeWidth: 1),
          getDrawingVerticalLine: (_) => FlLine(color: Colors.transparent),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (v, _) => Text(
                  'Rs.${(v / 1000).toStringAsFixed(0)}k',
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                final parts = data[idx].key.split('/');
                return Text(
                    parts.length >= 2
                        ? '${parts[0]}/${parts[1]}'
                        : data[idx].key,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 9));
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), data[i].value),
            ),
            isCurved: true,
            color: AppTheme.accentColor,
            barWidth: 2.5,
            dotData: FlDotData(
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3, color: AppTheme.accentColor, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accentColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final Map<String, double> dataMap;
  final List<Color> colors;
  const _CategoryPieChart({required this.dataMap, required this.colors});

  @override
  Widget build(BuildContext context) {
    final entries = dataMap.entries.toList();
    final total = entries.fold(0.0, (s, e) => s + e.value);
    return PieChart(
      PieChartData(
        sections: List.generate(entries.length, (index) {
          final entry = entries[index];
          final color = colors[index % colors.length];
          final pct = total > 0 ? (entry.value / total * 100) : 0;
          return PieChartSectionData(
            color: color,
            value: entry.value,
            title: '${pct.toStringAsFixed(0)}%',
            radius: 60,
            titleStyle: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  const _BarRow(
      {required this.label,
      required this.value,
      required this.max,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? value / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              Text(AppHelpers.formatCurrency(value),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.toDouble(),
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
