import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Category.dart';
import '../models/BudgetGoal.dart';

class BudgetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Categories ---
  Stream<List<Category>> getCategories(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addCategory(Category category) {
    return _db
        .collection('users')
        .doc(category.userId)
        .collection('categories')
        .add(category.toMap());
  }

  Future<void> updateCategory(Category category) {
    return _db
        .collection('users')
        .doc(category.userId)
        .collection('categories')
        .doc(category.id)
        .update(category.toMap());
  }

  Future<void> deleteCategory(String userId, String categoryId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  Future<void> deleteAllCategories(String userId, List<String> categoryIds) async {
    final batch = _db.batch();
    for (var id in categoryIds) {
      final docRef = _db
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(id);
      batch.delete(docRef);
    }
    return batch.commit();
  }

  // --- Budget Goals ---
  Stream<List<BudgetGoal>> getBudgetGoals(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('savings_goals')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BudgetGoal.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addBudgetGoal(BudgetGoal goal) {
    return _db
        .collection('users')
        .doc(goal.userId)
        .collection('savings_goals')
        .add(goal.toMap());
  }

  Future<void> updateBudgetGoal(BudgetGoal goal) {
    return _db
        .collection('users')
        .doc(goal.userId)
        .collection('savings_goals')
        .doc(goal.id)
        .update(goal.toMap());
  }

  Future<void> deleteBudgetGoal(String userId, String goalId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('savings_goals')
        .doc(goalId)
        .delete();
  }
}
