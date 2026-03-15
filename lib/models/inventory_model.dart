import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final String type; // 'tyre' or 'tube'
  final String category;
  final String brand;
  final String size;
  final int stockQuantity;
  final double buyingPrice;
  final double sellingPrice;
  final int lowStockAlert;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  InventoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.brand,
    required this.size,
    required this.stockQuantity,
    required this.buyingPrice,
    required this.sellingPrice,
    this.lowStockAlert = 5,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  bool get isLowStock => stockQuantity <= lowStockAlert;
  bool get isOutOfStock => stockQuantity == 0;
  double get profitMargin => sellingPrice - buyingPrice;
  double get profitPercent =>
      buyingPrice > 0 ? ((profitMargin / buyingPrice) * 100) : 0;

  InventoryItem copyWith({
    int? stockQuantity,
    double? buyingPrice,
    double? sellingPrice,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id,
      name: name,
      type: type,
      category: category,
      brand: brand,
      size: size,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      lowStockAlert: lowStockAlert,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'category': category,
        'brand': brand,
        'size': size,
        'stockQuantity': stockQuantity,
        'buyingPrice': buyingPrice,
        'sellingPrice': sellingPrice,
        'lowStockAlert': lowStockAlert,
        'description': description,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'userId': userId,
      };

  factory InventoryItem.fromMap(Map<String, dynamic> map) => InventoryItem(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        type: map['type'] ?? 'tyre',
        category: map['category'] ?? '',
        brand: map['brand'] ?? '',
        size: map['size'] ?? '',
        stockQuantity: map['stockQuantity'] ?? 0,
        buyingPrice: (map['buyingPrice'] ?? 0).toDouble(),
        sellingPrice: (map['sellingPrice'] ?? 0).toDouble(),
        lowStockAlert: map['lowStockAlert'] ?? 5,
        description: map['description'],
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        userId: map['userId'] ?? '',
      );

  factory InventoryItem.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return InventoryItem.fromMap(map);
  }
}