import 'package:cloud_firestore/cloud_firestore.dart';
import 'sale_model.dart';

// ─── Payment Record ───────────────────────────────────────────

class CreditPayment {
  final String id;
  final double amount;
  final DateTime date;
  final String? notes;

  CreditPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'notes': notes,
      };

  factory CreditPayment.fromMap(Map<String, dynamic> map) => CreditPayment(
        id: map['id']?.toString() ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        date: (map['date'] as Timestamp).toDate(),
        notes: map['notes']?.toString(),
      );
}

// ─── Credit Sale Status ───────────────────────────────────────

enum CreditStatus { pending, partial, paid }

extension CreditStatusExt on CreditStatus {
  String get label {
    switch (this) {
      case CreditStatus.pending:
        return 'Pending';
      case CreditStatus.partial:
        return 'Partial';
      case CreditStatus.paid:
        return 'Paid';
    }
  }
}

// ─── Credit Sale ──────────────────────────────────────────────

class CreditSale {
  final String id;
  final String? customerId;
  final String customerName; // required for credit — must know who owes
  final String? customerPhone;
  final List<SaleItem> items;
  final double totalAmount; // subtotal of items
  final double totalProfit;
  final double discountAmount;
  final double serviceCharge;
  final double
      netAmount; // what is owed = totalAmount - discount + serviceCharge
  final double paidAmount; // sum of all payments received so far
  final List<CreditPayment> payments;
  final String? notes;
  final DateTime date; // date goods were borrowed
  final DateTime? dueDate; // optional promised return date
  final String userId;

  CreditSale({
    required this.id,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.items,
    required this.totalAmount,
    required this.totalProfit,
    this.discountAmount = 0.0,
    this.serviceCharge = 0.0,
    required this.netAmount,
    this.paidAmount = 0.0,
    this.payments = const [],
    this.notes,
    required this.date,
    this.dueDate,
    required this.userId,
  });

  double get remainingAmount =>
      (netAmount - paidAmount).clamp(0.0, double.infinity);

  bool get isFullyPaid => remainingAmount <= 0;

  CreditStatus get status {
    if (isFullyPaid) return CreditStatus.paid;
    if (paidAmount > 0) return CreditStatus.partial;
    return CreditStatus.pending;
  }

  bool get isOverdue {
    if (dueDate == null || isFullyPaid) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  CreditSale copyWith({
    double? paidAmount,
    List<CreditPayment>? payments,
  }) =>
      CreditSale(
        id: id,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        items: items,
        totalAmount: totalAmount,
        totalProfit: totalProfit,
        discountAmount: discountAmount,
        serviceCharge: serviceCharge,
        netAmount: netAmount,
        paidAmount: paidAmount ?? this.paidAmount,
        payments: payments ?? this.payments,
        notes: notes,
        date: date,
        dueDate: dueDate,
        userId: userId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'items': items.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'totalProfit': totalProfit,
        'discountAmount': discountAmount,
        'serviceCharge': serviceCharge,
        'netAmount': netAmount,
        'paidAmount': paidAmount,
        'payments': payments.map((e) => e.toMap()).toList(),
        'notes': notes,
        'date': Timestamp.fromDate(date),
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'userId': userId,
      };

  factory CreditSale.fromMap(Map<String, dynamic> map) => CreditSale(
        id: map['id']?.toString() ?? '',
        customerId: map['customerId']?.toString(),
        customerName: map['customerName']?.toString() ?? 'Unknown',
        customerPhone: map['customerPhone']?.toString(),
        items: (map['items'] as List<dynamic>? ?? [])
            .map((e) => SaleItem.fromMap(e as Map<String, dynamic>))
            .toList(),
        totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
        totalProfit: (map['totalProfit'] as num?)?.toDouble() ?? 0.0,
        discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
        serviceCharge: (map['serviceCharge'] as num?)?.toDouble() ?? 0.0,
        netAmount: (map['netAmount'] as num?)?.toDouble() ?? 0.0,
        paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
        payments: (map['payments'] as List<dynamic>? ?? [])
            .map((e) => CreditPayment.fromMap(e as Map<String, dynamic>))
            .toList(),
        notes: map['notes']?.toString(),
        date: (map['date'] as Timestamp).toDate(),
        dueDate: map['dueDate'] != null
            ? (map['dueDate'] as Timestamp).toDate()
            : null,
        userId: map['userId']?.toString() ?? '',
      );
}
