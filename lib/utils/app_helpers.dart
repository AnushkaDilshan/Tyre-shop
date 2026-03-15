import 'package:intl/intl.dart';
import 'app_constants.dart';

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