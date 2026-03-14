import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String id;
  final String userId;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String? description;
  final String type; // 'income' or 'expense'

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.description,
    required this.type,
  });

  factory Transaction.fromMap(String id, Map<String, dynamic> map) {
    return Transaction(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      categoryId: map['categoryId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      description: map['description'],
      type: map['type'] ?? 'expense',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'categoryId': categoryId,
      'date': Timestamp.fromDate(date),
      'description': description,
      'type': type,
    };
  }
}
