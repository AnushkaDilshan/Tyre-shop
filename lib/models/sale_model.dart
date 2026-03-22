import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItem {
  final String itemId;
  final String itemName;
  final String itemType;
  final String category;
  final String brand;
  final String size;
  final int quantity;
  final double buyingPrice;
  final double sellingPrice;
  final double profit;

  SaleItem({
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.category,
    required this.brand,
    required this.size,
    required this.quantity,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.profit,
  });

  double get totalSelling => sellingPrice * quantity;
  double get totalBuying => buyingPrice * quantity;
  double get totalProfit => profit * quantity;

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'itemName': itemName,
        'itemType': itemType,
        'category': category,
        'brand': brand,
        'size': size,
        'quantity': quantity,
        'buyingPrice': buyingPrice,
        'sellingPrice': sellingPrice,
        'profit': profit,
      };

  factory SaleItem.fromMap(Map<String, dynamic> map) => SaleItem(
        itemId: map['itemId']?.toString() ?? '',
        itemName: map['itemName']?.toString() ?? '',
        itemType: map['itemType']?.toString() ?? '',
        category: map['category']?.toString() ?? '',
        brand: map['brand']?.toString() ?? '',
        size: map['size']?.toString() ?? '',
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
        buyingPrice: (map['buyingPrice'] as num?)?.toDouble() ?? 0.0,
        sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
        profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
      );
}

class Sale {
  final String id;
  final String? customerId;
  final String? customerName;
  final List<SaleItem> items;
  final double totalAmount;
  final double totalProfit;
  final double discountAmount;
  final double serviceCharge;
  final String paymentMethod;
  final String? notes;
  final DateTime date;
  final String userId;

  Sale({
    required this.id,
    this.customerId,
    this.customerName,
    required this.items,
    required this.totalAmount,
    required this.totalProfit,
    this.discountAmount = 0.0,
    this.serviceCharge = 0.0,
    required this.paymentMethod,
    this.notes,
    required this.date,
    required this.userId,
  });

  double get netAmount => totalAmount - discountAmount + serviceCharge;

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'items': items.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'totalProfit': totalProfit,
        'discountAmount': discountAmount,
        'serviceCharge': serviceCharge,
        'paymentMethod': paymentMethod,
        'notes': notes,
        'date': Timestamp.fromDate(date),
        'userId': userId,
      };

  factory Sale.fromMap(Map<String, dynamic> map) => Sale(
        id: map['id']?.toString() ?? '',
        customerId: map['customerId']?.toString(),
        customerName: map['customerName']?.toString(),
        items: (map['items'] as List<dynamic>? ?? [])
            .map((e) => SaleItem.fromMap(e as Map<String, dynamic>))
            .toList(),
        totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
        totalProfit: (map['totalProfit'] as num?)?.toDouble() ?? 0.0,
        discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
        serviceCharge: (map['serviceCharge'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: map['paymentMethod']?.toString() ?? 'Cash',
        notes: map['notes']?.toString(),
        date: (map['date'] as Timestamp).toDate(),
        userId: map['userId']?.toString() ?? '',
      );

  factory Sale.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Sale.fromMap(map);
  }
}