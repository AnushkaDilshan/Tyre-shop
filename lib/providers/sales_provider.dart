import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/sale_model.dart';
import '../services/firebase_service.dart';
import '../utils/app_helpers.dart';

class SalesProvider extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  final Uuid _uuid = const Uuid();

  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  double get todayRevenue {
    final today = AppHelpers.startOfDay(DateTime.now());
    return _sales
        .where((s) => s.date.isAfter(today))
        .fold(0, (sum, s) => sum + s.netAmount);
  }

  double get todayProfit {
    final today = AppHelpers.startOfDay(DateTime.now());
    return _sales
        .where((s) => s.date.isAfter(today))
        .fold(0, (sum, s) => sum + s.totalProfit - s.discountAmount);
  }

  int get todaySalesCount {
    final today = AppHelpers.startOfDay(DateTime.now());
    return _sales.where((s) => s.date.isAfter(today)).length;
  }

  List<Sale> get filteredSales {
    final start = AppHelpers.startOfDay(_selectedDate);
    final end = AppHelpers.endOfDay(_selectedDate);
    return _sales
        .where((s) => s.date.isAfter(start) && s.date.isBefore(end))
        .toList();
  }

  void loadSales() {
    _isLoading = true;
    notifyListeners();
    _service
        .getSalesStream(
      from: DateTime.now().subtract(const Duration(days: 90)),
    )
        .listen((sales) {
      _sales = sales;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> addSale({
    required List<SaleItem> items,
    String? customerId,
    String? customerName,
    double discountAmount = 0,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final totalAmount = items.fold(0.0, (sum, i) => sum + i.totalSelling);
      final totalProfit = items.fold(0.0, (sum, i) => sum + i.totalProfit);
      final sale = Sale(
        id: _uuid.v4(),
        customerId: customerId,
        customerName: customerName,
        items: items,
        totalAmount: totalAmount,
        totalProfit: totalProfit,
        discountAmount: discountAmount,
        paymentMethod: paymentMethod,
        notes: notes,
        date: DateTime.now(),
        userId: _service.userId,
      );
      await _service.addSale(sale);
    } catch (_) {}
    loadSales();
    return true;
  }

  Future<bool> deleteSale(String saleId) async {
    try {
      await _service.deleteSale(saleId);
    } catch (_) {}
    return true;
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void clearData() {
    _sales = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<List<Sale>> getSalesForRange(DateTime from, DateTime to) async {
    return await _service.getSales(from: from, to: to);
  }
}
