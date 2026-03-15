import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_model.dart';
import '../services/firebase_service.dart';

class InventoryProvider extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  final Uuid _uuid = const Uuid();

  List<InventoryItem> _tyres = [];
  List<InventoryItem> _tubes = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<InventoryItem> get tyres => _filter(_tyres);
  List<InventoryItem> get tubes => _filter(_tubes);
  List<InventoryItem> get allItems => [..._tyres, ..._tubes];
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalTyreStock => _tyres.fold(0, (sum, t) => sum + t.stockQuantity);
  int get totalTubeStock => _tubes.fold(0, (sum, t) => sum + t.stockQuantity);
  int get lowStockCount => allItems.where((i) => i.isLowStock).length;

  List<InventoryItem> get lowStockItems =>
      allItems.where((i) => i.isLowStock && !i.isOutOfStock).toList();
  List<InventoryItem> get outOfStockItems =>
      allItems.where((i) => i.isOutOfStock).toList();

  List<InventoryItem> _filter(List<InventoryItem> items) {
    if (_searchQuery.isEmpty) return items;
    return items
        .where((i) =>
            i.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            i.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            i.size.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void loadInventory() {
    _isLoading = true;
    notifyListeners();

    _service.getInventoryStream('tyre').listen((tyres) {
      _tyres = tyres;
      _isLoading = false;
      notifyListeners();
    });

    _service.getInventoryStream('tube').listen((tubes) {
      _tubes = tubes;
      notifyListeners();
    });
  }

  Future<bool> addItem({
    required String name,
    required String type,
    required String category,
    required String brand,
    required String size,
    required int stockQuantity,
    required double buyingPrice,
    required double sellingPrice,
    int lowStockAlert = 5,
    String? description,
  }) async {
    try {
      final item = InventoryItem(
        id: _uuid.v4(),
        name: name,
        type: type,
        category: category,
        brand: brand,
        size: size,
        stockQuantity: stockQuantity,
        buyingPrice: buyingPrice,
        sellingPrice: sellingPrice,
        lowStockAlert: lowStockAlert,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: _service.userId,
      );
      await _service.addInventoryItem(item);
    } catch (_) {}
    loadInventory();
    return true;
  }
void clearData() {
  _tyres = [];
  _tubes = [];
  _isLoading = false;
  notifyListeners();
}
  Future<bool> updateItem(InventoryItem item) async {
    try {
      await _service
          .updateInventoryItem(item.copyWith(updatedAt: DateTime.now()));
    } catch (_) {}
    loadInventory();
    return true;
  }

  Future<bool> deleteItem(String id, String type) async {
    try {
      await _service.deleteInventoryItem(id, type);
    } catch (_) {}
    loadInventory();
    return true;
  }

  Future<bool> adjustStock(String id, String type, int newQty) async {
    try {
      await _service.adjustStock(id, type, newQty);
    } catch (_) {}
    loadInventory();
    return true;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  InventoryItem? findById(String id) {
    try {
      return allItems.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }
}
