import 'package:intl/intl.dart';

class AppConstants {
  static const String appName = 'Tyre Shop Manager';
  static const String currency = 'Rs.';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String salesCollection = 'sales';
  static const String expensesCollection = 'expenses';
  static const String tyresCollection = 'tyres';
  static const String tubesCollection = 'tubes';
  static const String customersCollection = 'customers';
  static const String creditSalesCollection = 'credit_sales';
  // Tyre categories
  static const List<String> tyreCategories = [
    'Car Tyre',
    'Motorbike Tyre',
    'Three-Wheeler Tyre',
    'Van Tyre',
    'Truck Tyre',
    'Bicycle Tyre',
  ];

  // Tube categories
  static const List<String> tubeCategories = [
    'Car Tube',
    'Motorbike Tube',
    'Three-Wheeler Tube',
    'Van Tube',
    'Truck Tube',
    'Bicycle Tube',
  ];

  // Expense categories
  static const List<String> expenseCategories = [
    'Stock Purchase',
    'Rent',
    'Electricity',
    'Staff Salary',
    'Tools & Equipment',
    'Transport',
    'Other',
  ];

  // Payment methods
  static const List<String> paymentMethods = [
    'Cash',
    'Card',
    'Bank Transfer',
    'Credit',
  ];
}

class AppHelpers {
  static String formatCurrency(double amount) {
    return '${AppConstants.currency} ${NumberFormat('#,##0.00').format(amount)}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String todayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static String weekKey(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(weekStart);
  }

  static String monthKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }
}
