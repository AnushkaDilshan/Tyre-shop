import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sale_model.dart';
import '../models/expense_model.dart';
import '../models/inventory_model.dart';
import '../models/customer_model.dart';
import '../utils/app_constants.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  // ─── AUTH ────────────────────────────────────────────────
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> signUp(String email, String password,
      {String shopName = 'My Tyre Shop'}) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

    try {
      await _db.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'shopName': shopName,
        'createdAt': Timestamp.now(),
      });
    } catch (_) {}

    return credential;
  }

  Future<void> signOut() async => await _auth.signOut();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── SALES ───────────────────────────────────────────────
  CollectionReference get _salesRef =>
      _db.collection(AppConstants.salesCollection);

  Future<void> addSale(Sale sale) async {
    try {
      await _salesRef.doc(sale.id).set(sale.toMap());
    } catch (_) {}
    if (sale.customerId != null) {
      try {
        await _updateCustomerStats(sale.customerId!, sale.totalAmount);
      } catch (_) {}
    }
    for (final item in sale.items) {
      try {
        await _decrementStock(item.itemId, item.itemType, item.quantity);
      } catch (_) {}
    }
  }

  Future<void> deleteSale(String saleId) async {
    try {
      await _salesRef.doc(saleId).delete();
    } catch (_) {}
  }

  Stream<List<Sale>> getSalesStream({DateTime? from, DateTime? to}) {
    Query query = _salesRef.where('userId', isEqualTo: userId);
    if (from != null) {
      query =
          query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    return query.orderBy('date', descending: true).snapshots().map((snap) =>
        snap.docs
            .map((d) => Sale.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<List<Sale>> getSales({DateTime? from, DateTime? to}) async {
    try {
      Query query = _salesRef.where('userId', isEqualTo: userId);
      if (from != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(from));
      }
      if (to != null) {
        query =
            query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
      }
      final snap = await query.orderBy('date', descending: true).get();
      return snap.docs
          .map((d) => Sale.fromMap(d.data() as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── EXPENSES ────────────────────────────────────────────
  CollectionReference get _expensesRef =>
      _db.collection(AppConstants.expensesCollection);

  Future<void> addExpense(Expense expense) async {
    try {
      await _expensesRef.doc(expense.id).set(expense.toMap());
    } catch (_) {}
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _expensesRef.doc(expense.id).update(expense.toMap());
    } catch (_) {}
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _expensesRef.doc(expenseId).delete();
    } catch (_) {}
  }

  Stream<List<Expense>> getExpensesStream({DateTime? from, DateTime? to}) {
    Query query = _expensesRef.where('userId', isEqualTo: userId);
    if (from != null) {
      query =
          query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    return query.orderBy('date', descending: true).snapshots().map((snap) =>
        snap.docs
            .map((d) => Expense.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<List<Expense>> getExpenses({DateTime? from, DateTime? to}) async {
    try {
      Query query = _expensesRef.where('userId', isEqualTo: userId);
      if (from != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(from));
      }
      if (to != null) {
        query =
            query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
      }
      final snap = await query.orderBy('date', descending: true).get();
      return snap.docs
          .map((d) => Expense.fromMap(d.data() as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── INVENTORY ───────────────────────────────────────────
  CollectionReference _inventoryRef(String type) {
    return _db.collection(type == 'tyre'
        ? AppConstants.tyresCollection
        : AppConstants.tubesCollection);
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    try {
      await _inventoryRef(item.type).doc(item.id).set(item.toMap());
    } catch (_) {}
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      await _inventoryRef(item.type).doc(item.id).update(item.toMap());
    } catch (_) {}
  }

  Future<void> deleteInventoryItem(String id, String type) async {
    try {
      await _inventoryRef(type).doc(id).delete();
    } catch (_) {}
  }

  Stream<List<InventoryItem>> getInventoryStream(String type) {
    return _inventoryRef(type)
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => InventoryItem.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<List<InventoryItem>> getInventory(String type) async {
    try {
      final snap = await _inventoryRef(type)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .orderBy('name')
          .get();
      return snap.docs
          .map((d) => InventoryItem.fromMap(d.data() as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _decrementStock(String itemId, String type, int quantity) async {
    try {
      final ref = _inventoryRef(type).doc(itemId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (snap.exists) {
          final current =
              (snap.data() as Map<String, dynamic>)['stockQuantity'] ?? 0;
          tx.update(ref, {
            'stockQuantity': (current - quantity).clamp(0, 999999),
            'updatedAt': Timestamp.now(),
          });
        }
      });
    } catch (_) {}
  }

  Future<void> adjustStock(String itemId, String type, int newQty) async {
    try {
      await _inventoryRef(type).doc(itemId).update({
        'stockQuantity': newQty,
        'updatedAt': Timestamp.now(),
      });
    } catch (_) {}
  }

  // ─── CUSTOMERS ───────────────────────────────────────────
  CollectionReference get _customersRef =>
      _db.collection(AppConstants.customersCollection);

  Future<void> addCustomer(Customer customer) async {
    try {
      await _customersRef.doc(customer.id).set(customer.toMap());
    } catch (_) {}
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _customersRef.doc(customer.id).update(customer.toMap());
    } catch (_) {}
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _customersRef.doc(customerId).delete();
    } catch (_) {}
  }

  Stream<List<Customer>> getCustomersStream() {
    return _customersRef
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Customer.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final snap = await _customersRef
          .where('userId', isEqualTo: userId)
          .orderBy('name')
          .get();
      return snap.docs
          .map((d) => Customer.fromMap(d.data() as Map<String, dynamic>))
          .where((c) =>
              c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.phone.contains(query))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _updateCustomerStats(String customerId, double amount) async {
    try {
      final ref = _customersRef.doc(customerId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          tx.update(ref, {
            'totalPurchases':
                ((data['totalPurchases'] ?? 0) as num).toDouble() + amount,
            'totalVisits': ((data['totalVisits'] ?? 0) as num).toInt() + 1,
          });
        }
      });
    } catch (_) {}
  }
}
