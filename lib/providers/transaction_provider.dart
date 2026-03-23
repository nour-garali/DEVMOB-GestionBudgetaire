import 'dart:async';
import 'package:flutter/material.dart';
import '../models/Category.dart';
import '../models/Transaction.dart';
import '../services/BudgetService.dart';
import '../services/TransactionService.dart';

class TransactionProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();
  final TransactionService _transactionService = TransactionService();
  
  List<Category> _categories = [];
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  bool _hasAttemptedInitialSeed = false;
  
  List<Category> get categories => _categories;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  
  StreamSubscription<List<Category>>? _categoriesSub;
  StreamSubscription<List<Transaction>>? _transactionsSub;

  double get totalIncome {
    return _transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  double get currentMonthExpenseTotal {
    final now = DateTime.now();
    return getMonthlyExpenseTotal(now.month, now.year);
  }

  double getMonthlyExpenseTotal(int month, int year) {
    return _transactions
        .where((t) => 
            t.type == 'expense' && 
            t.date.month == month && 
            t.date.year == year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  

  double getCategoryMonthlyTotal(String categoryId) {
    final now = DateTime.now();
    return getCategoryTotalByMonth(categoryId, now.month, now.year);
  }

  double getCategoryTotalByMonth(String categoryId, int month, int year) {
    return _transactions
        .where((t) => 
            t.categoryId == categoryId && 
            t.date.month == month && 
            t.date.year == year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  void init(String userId) {
    _isLoading = true;
    notifyListeners();

    _categoriesSub?.cancel();
    _transactionsSub?.cancel();

    _categoriesSub = _budgetService.getCategories(userId).listen((event) {
      _categories = event;
      _isLoading = false;
      if (_categories.isEmpty && !_hasAttemptedInitialSeed) {
        _hasAttemptedInitialSeed = true;
        // La création de catégories par défaut a été désactivée à la demande de l'utilisateur.
      }
      notifyListeners();
    });

    _transactionsSub = _transactionService.getTransactions(userId).listen((event) {
      _transactions = event;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _seedDefaultCategories(String userId) async {
    final defaults = [
      Category(id: '', userId: userId, name: 'Salaire', icon: Icons.payments_rounded, color: Colors.green, type: CategoryType.income),
      Category(id: '', userId: userId, name: 'Loyer', icon: Icons.home_rounded, color: Colors.indigo, type: CategoryType.expense),
      Category(id: '', userId: userId, name: 'Alimentation', icon: Icons.restaurant_rounded, color: Colors.orange, type: CategoryType.expense),
      Category(id: '', userId: userId, name: 'Transport', icon: Icons.commute_rounded, color: Colors.blue, type: CategoryType.expense),
      Category(id: '', userId: userId, name: 'Restaurant', icon: Icons.fastfood_rounded, color: Colors.red, type: CategoryType.expense),
    ];

    for (var cat in defaults) {
      await addCategory(cat);
    }
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
    _transactionsSub?.cancel();
    super.dispose();
  }

  // CRUD wrappers
  Future<void> addTransaction(Transaction transaction) => _transactionService.addTransaction(transaction);
  Future<void> updateTransaction(Transaction transaction) => _transactionService.updateTransaction(transaction);
  Future<void> deleteTransaction(String userId, String transactionId) => _transactionService.deleteTransaction(userId, transactionId);
  
  Future<void> addCategory(Category category) => _budgetService.addCategory(category);
  Future<void> updateCategory(Category category) => _budgetService.updateCategory(category);
  Future<void> deleteCategory(String userId, String categoryId) => _budgetService.deleteCategory(userId, categoryId);

  Future<void> deleteAllCategories(String userId) async {
    final ids = _categories.map((c) => c.id).toList();
    if (ids.isEmpty) return;
    
    // Set flag to true so we don't immediately re-seed when stream emits empty list
    _hasAttemptedInitialSeed = true; 
    
    await _budgetService.deleteAllCategories(userId, ids);
    notifyListeners();
  }

  Future<void> resetAllData(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final txIds = _transactions.map((t) => t.id).toList();
      final catIds = _categories.map((c) => c.id).toList();

      if (txIds.isNotEmpty) {
        await _transactionService.deleteAllTransactions(userId, txIds);
      }
      
      if (catIds.isNotEmpty) {
        _hasAttemptedInitialSeed = true; // Prevent automatic re-seeding
        await _budgetService.deleteAllCategories(userId, catIds);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getCategoryName(String categoryId) {
    if (categoryId.isEmpty) return 'Sans catégorie';
    if (categoryId == 'All') return 'Toutes les catégories';
    
    final cat = _categories.where((c) => c.id == categoryId);
    if (cat.isNotEmpty) {
      final name = cat.first.name;
      // If the name is empty or identical to the ID, try to see if it's a seed error
      return name.isNotEmpty ? name : 'Catégorie';
    }
    
    return 'Général'; 
  }

  IconData getCategoryIcon(String categoryId) {
    if (categoryId.isEmpty || categoryId == 'All') return Icons.receipt_rounded;
    
    final cat = _categories.where((c) => c.id == categoryId);
    if (cat.isNotEmpty) {
      return cat.first.icon;
    }
    
    return Icons.receipt_rounded;
  }
}
