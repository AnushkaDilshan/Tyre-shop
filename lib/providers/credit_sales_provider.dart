import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/credit_sale_model.dart';
import '../models/sale_model.dart';
import '../services/firebase_service.dart';
import 'sales_provider.dart';

class CreditSalesProvider extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  final Uuid _uuid = const Uuid();

  List<CreditSale> _creditSales = [];
  bool _isLoading = false;
  String? _error;
  bool _showUnpaidOnly = false;

  List<CreditSale> get creditSales => _creditSales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showUnpaidOnly => _showUnpaidOnly;

  // ─── Computed summaries ────────────────────────────────────────────────────

  double get totalOutstanding =>
      _creditSales.fold(0.0, (sum, cs) => sum + cs.remainingAmount);

  int get unpaidCount => _creditSales.where((cs) => !cs.isFullyPaid).length;

  int get overdueCount => _creditSales.where((cs) => cs.isOverdue).length;

  List<CreditSale> get filteredSales {
    if (_showUnpaidOnly) {
      return _creditSales.where((cs) => !cs.isFullyPaid).toList();
    }
    return _creditSales;
  }

  // ─── Load ──────────────────────────────────────────────────────────────────

  void loadCreditSales() {
    _isLoading = true;
    notifyListeners();
    _service.getCreditSalesStream().listen(
      (sales) {
        _creditSales = sales;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ─── Add Credit Sale ───────────────────────────────────────────────────────

  Future<bool> addCreditSale({
    required List<SaleItem> items,
    String? customerId,
    required String customerName,
    String? customerPhone,
    double discountAmount = 0,
    double serviceCharge = 0,
    String? notes,
    DateTime? dueDate,
  }) async {
    try {
      final totalAmount = items.fold(0.0, (sum, i) => sum + i.totalSelling);
      final totalProfit =
          items.fold(0.0, (sum, i) => sum + i.totalProfit) + serviceCharge;
      final netAmount = totalAmount - discountAmount + serviceCharge;

      final creditSale = CreditSale(
        id: _uuid.v4(),
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        items: items,
        totalAmount: totalAmount,
        totalProfit: totalProfit,
        discountAmount: discountAmount,
        serviceCharge: serviceCharge,
        netAmount: netAmount,
        paidAmount: 0,
        payments: [],
        notes: notes,
        date: DateTime.now(),
        dueDate: dueDate,
        userId: _service.userId,
      );

      // ── Optimistic update: add to local list immediately so UI
      //    shows the new entry without waiting for Firestore stream ──
      _creditSales = [creditSale, ..._creditSales];
      notifyListeners();

      await _service.addCreditSale(creditSale);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Record Payment ────────────────────────────────────────────────────────

  Future<bool> recordPayment({
    required CreditSale creditSale,
    required double amount,
    String? notes,
  }) async {
    try {
      final payment = CreditPayment(
        id: _uuid.v4(),
        amount: amount,
        date: DateTime.now(),
        notes: notes,
      );
      final newPaidAmount =
          (creditSale.paidAmount + amount).clamp(0.0, creditSale.netAmount);

      // Optimistic local update
      final updatedSale = creditSale.copyWith(
        paidAmount: newPaidAmount,
        payments: [...creditSale.payments, payment],
      );
      _creditSales = _creditSales
          .map((cs) => cs.id == creditSale.id ? updatedSale : cs)
          .toList();
      notifyListeners();

      // Save payment to Firestore
      await _service.recordCreditPayment(
        creditSaleId: creditSale.id,
        payment: payment,
        newPaidAmount: newPaidAmount,
      );

      // ── If fully paid, create a Sale record so it shows in revenue ──
      final isNowFullyPaid = newPaidAmount >= creditSale.netAmount - 0.01;
      if (isNowFullyPaid) {
        await _service.addSaleFromCreditSale(creditSale);
      }

      return true;
    } catch (e) {
      print('recordPayment error: $e');
      // Revert optimistic update on failure
      _creditSales = _creditSales
          .map((cs) => cs.id == creditSale.id ? creditSale : cs)
          .toList();
      notifyListeners();
      return false;
    }
  }
  // ─── Delete ────────────────────────────────────────────────────────────────

  Future<bool> deleteCreditSale(CreditSale creditSale,
      {bool restoreStock = false}) async {
    try {
      await _service.deleteCreditSale(
        creditSale.id,
        itemsToRestore: restoreStock
            ? creditSale.items
                .map((i) => {
                      'itemId': i.itemId,
                      'itemType': i.itemType,
                      'quantity': i.quantity,
                    })
                .toList()
            : null,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Filter toggle ─────────────────────────────────────────────────────────

  void toggleUnpaidFilter() {
    _showUnpaidOnly = !_showUnpaidOnly;
    notifyListeners();
  }

  void clearData() {
    _creditSales = [];
    _isLoading = false;
    notifyListeners();
  }
}
