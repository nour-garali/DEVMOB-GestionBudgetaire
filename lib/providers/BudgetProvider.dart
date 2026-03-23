import 'package:flutter/foundation.dart';
import '../models/BudgetGoal.dart';
import '../services/BudgetService.dart';

class BudgetGoalProvider with ChangeNotifier {
  final BudgetService _budgetService = BudgetService();
  List<BudgetGoal> _goals = [];
  bool _isLoading = false;

  List<BudgetGoal> get goals => _goals;
  bool get isLoading => _isLoading;

  void init(String userId) {
    _isLoading = true;
    _budgetService.getBudgetGoals(userId).listen((goals) {
      _goals = goals;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addGoal(BudgetGoal goal) async {
    await _budgetService.addBudgetGoal(goal);
  }

  Future<void> updateGoal(BudgetGoal goal) async {
    await _budgetService.updateBudgetGoal(goal);
  }

  Future<void> deleteGoal(String userId, String goalId) async {
    await _budgetService.deleteBudgetGoal(userId, goalId);
  }
}
