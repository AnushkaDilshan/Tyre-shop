import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';
import '../services/firebase_service.dart';
import '../utils/app_helpers.dart';

class ExpenseProvider extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  final Uuid _uuid = const Uuid();

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get todayExpenses {
    final today = AppHelpers.startOfDay(DateTime.now());
    return _expenses
        .where((e) => e.date.isAfter(today))
        .fold(0, (sum, e) => sum + e.amount);
  }

  double get monthExpenses {
    final start = AppHelpers.startOfMonth(DateTime.now());
    return _expenses
        .where((e) => e.date.isAfter(start))
        .fold(0, (sum, e) => sum + e.amount);
  }

  Map<String, double> get expenseByCategory {
    final map = <String, double>{};
    for (final e in _expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  void loadExpenses() {
    _isLoading = true;
    notifyListeners();
    _service
        .getExpensesStream(
      from: DateTime.now().subtract(const Duration(days: 90)),
    )
        .listen((expenses) {
      _expenses = expenses;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> addExpense({
    required String title,
    required String category,
    required double amount,
    String? description,
    DateTime? date,
  }) async {
    try {
      final expense = Expense(
        id: _uuid.v4(),
        title: title,
        category: category,
        amount: amount,
        description: description,
        date: date ?? DateTime.now(),
        userId: _service.userId,
      );
      await _service.addExpense(expense);
    } catch (_) {}
    loadExpenses();
    return true;
  }
void clearData() {
  _expenses = [];
  _isLoading = false;
  notifyListeners();
}
  Future<bool> deleteExpense(String id) async {
    try {
      await _service.deleteExpense(id);
    } catch (_) {}
    return true;
  }

  Future<List<Expense>> getExpensesForRange(DateTime from, DateTime to) async {
    return await _service.getExpenses(from: from, to: to);
  }
}
