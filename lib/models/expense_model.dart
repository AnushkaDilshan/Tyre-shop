import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String? description;
  final DateTime date;
  final String userId;

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    this.description,
    required this.date,
    required this.userId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'amount': amount,
        'description': description,
        'date': Timestamp.fromDate(date),
        'userId': userId,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        category: map['category'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        description: map['description'],
        date: (map['date'] as Timestamp).toDate(),
        userId: map['userId'] ?? '',
      );

  factory Expense.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Expense.fromMap(map);
  }
}