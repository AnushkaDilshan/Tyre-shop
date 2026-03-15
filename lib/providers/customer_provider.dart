import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/customer_model.dart';
import '../services/firebase_service.dart';

class CustomerProvider extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  final Uuid _uuid = const Uuid();

  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<Customer> get customers => _filtered;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCustomers => _customers.length;

  List<Customer> get _filtered {
    if (_searchQuery.isEmpty) return _customers;
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.phone.contains(_searchQuery) ||
            (c.vehicleNumber
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false))
        .toList();
  }

  void loadCustomers() {
    _isLoading = true;
    notifyListeners();
    _service.getCustomersStream().listen((customers) {
      _customers = customers;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? vehicleType,
    String? vehicleNumber,
  }) async {
    try {
      final customer = Customer(
        id: _uuid.v4(),
        name: name,
        phone: phone,
        email: email,
        address: address,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        createdAt: DateTime.now(),
        userId: _service.userId,
      );
      await _service.addCustomer(customer);
    } catch (_) {}
     loadCustomers();
    return true;
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      await _service.updateCustomer(customer);
    } catch (_) {}
    return true;
  }
void clearData() {
  _customers = [];
  _isLoading = false;
  notifyListeners();
}
  Future<bool> deleteCustomer(String id) async {
    try {
      await _service.deleteCustomer(id);
    } catch (_) {}
    return true;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Customer? findById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}