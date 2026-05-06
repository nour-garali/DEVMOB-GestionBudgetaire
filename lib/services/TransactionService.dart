import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/Transaction.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Transaction>> getTransactions(String userId) {
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final transactions = snapshot.docs
            .map((doc) => Transaction.fromMap(doc.id, doc.data()))
            .toList();
          // Sort client-side to avoid needing a composite index in Firestore
          transactions.sort((a, b) => b.date.compareTo(a.date));
          return transactions;
        });
  }

  Future<void> addTransaction(Transaction transaction) {
    return _db
        .collection('transactions')
        .add(transaction.toMap());
  }

  Future<void> updateTransaction(Transaction transaction) {
    return _db
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  Future<void> deleteTransaction(String transactionId) {
    return _db
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  Future<void> deleteAllTransactions(List<String> transactionIds) async {
    final batch = _db.batch();
    for (var id in transactionIds) {
      final docRef = _db
          .collection('transactions')
          .doc(id);
      batch.delete(docRef);
    }
    return batch.commit();
  }
}
