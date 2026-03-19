import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/Transaction.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Transaction>> getTransactions(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Transaction.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addTransaction(Transaction transaction) {
    return _db
        .collection('users')
        .doc(transaction.userId)
        .collection('transactions')
        .add(transaction.toMap());
  }

  Future<void> updateTransaction(Transaction transaction) {
    return _db
        .collection('users')
        .doc(transaction.userId)
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  Future<void> deleteTransaction(String userId, String transactionId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  Future<void> deleteAllTransactions(String userId, List<String> transactionIds) async {
    final batch = _db.batch();
    for (var id in transactionIds) {
      final docRef = _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(id);
      batch.delete(docRef);
    }
    return batch.commit();
  }
}
