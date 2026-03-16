import 'package:flutter/material.dart';
import '../models/sale_model.dart';
import '../models/expense_model.dart';
import '../services/firebase_service.dart';
import '../utils/app_helpers.dart';

enum ReportType { daily, weekly, monthly }

class ReportData {
  final double totalRevenue;
  final double totalProfit;
  final double totalExpenses;
  final double netProfit;
  final int totalSales;
  final List<Sale> sales;
  final List<Expense> expenses;
  final Map<String, double> salesByCategory;
  final Map<String, double> expenseByCategory;
  final List<MapEntry<String, double>> dailyRevenue;

  ReportData({
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalSales,
    required this.sales,
    required this.expenses,
    required this.salesByCategory,
    required this.expenseByCategory,
    required this.dailyRevenue,
  });
}

class ReportProvider extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();

  ReportData? _reportData;
  bool _isLoading = false;
  String? _error;
  ReportType _reportType = ReportType.daily;
  DateTime _reportDate = DateTime.now();

  ReportData? get reportData => _reportData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ReportType get reportType => _reportType;
  DateTime get reportDate => _reportDate;

  Future<void> generateReport({
    ReportType? type,
    DateTime? date,
  }) async {
    _reportType = type ?? _reportType;
    _reportDate = date ?? _reportDate;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      DateTime from, to;
      switch (_reportType) {
        case ReportType.daily:
          from = AppHelpers.startOfDay(_reportDate);
          to = AppHelpers.endOfDay(_reportDate);
          break;
        case ReportType.weekly:
          from = AppHelpers.startOfDay(
              _reportDate.subtract(Duration(days: _reportDate.weekday - 1)));
          to = AppHelpers.endOfDay(from.add(const Duration(days: 6)));
          break;
        case ReportType.monthly:
          from = AppHelpers.startOfMonth(_reportDate);
          to = AppHelpers.endOfMonth(_reportDate);
          break;
      }

      final sales = await _service.getSales(from: from, to: to);
      final expenses = await _service.getExpenses(from: from, to: to);

      final totalRevenue =
          sales.fold(0.0, (sum, s) => sum + s.netAmount);
     final totalProfit =
    sales.fold(0.0, (sum, s) => sum + s.totalProfit - s.discountAmount);
      final totalExpenses =
          expenses.fold(0.0, (sum, e) => sum + e.amount);
      final netProfit = totalProfit - totalExpenses;

      // Sales by category
      final salesByCategory = <String, double>{};
      for (final sale in sales) {
        for (final item in sale.items) {
          salesByCategory[item.category] =
              (salesByCategory[item.category] ?? 0) + item.totalSelling;
        }
      }

      // Expenses by category
      final expenseByCategory = <String, double>{};
      for (final expense in expenses) {
        expenseByCategory[expense.category] =
            (expenseByCategory[expense.category] ?? 0) + expense.amount;
      }

      // Daily revenue trend
      final dailyMap = <String, double>{};
      for (final sale in sales) {
        final key = AppHelpers.formatDateShort(sale.date);
        dailyMap[key] = (dailyMap[key] ?? 0) + sale.netAmount;
      }
      final dailyRevenue = dailyMap.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      _reportData = ReportData(
        totalRevenue: totalRevenue,
        totalProfit: totalProfit,
        totalExpenses: totalExpenses,
        netProfit: netProfit,
        totalSales: sales.length,
        sales: sales,
        expenses: expenses,
        salesByCategory: salesByCategory,
        expenseByCategory: expenseByCategory,
        dailyRevenue: dailyRevenue,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setReportType(ReportType type) {
    _reportType = type;
    generateReport();
  }

  void setReportDate(DateTime date) {
    _reportDate = date;
    generateReport();
  }
}