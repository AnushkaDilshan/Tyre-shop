import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? vehicleType;
  final String? vehicleNumber;
  final double totalPurchases;
  final int totalVisits;
  final DateTime createdAt;
  final String userId;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.vehicleType,
    this.vehicleNumber,
    this.totalPurchases = 0,
    this.totalVisits = 0,
    required this.createdAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
        'totalPurchases': totalPurchases,
        'totalVisits': totalVisits,
        'createdAt': Timestamp.fromDate(createdAt),
        'userId': userId,
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        email: map['email'],
        address: map['address'],
        vehicleType: map['vehicleType'],
        vehicleNumber: map['vehicleNumber'],
        totalPurchases: (map['totalPurchases'] ?? 0).toDouble(),
        totalVisits: map['totalVisits'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        userId: map['userId'] ?? '',
      );

  factory Customer.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Customer.fromMap(map);
  }
}