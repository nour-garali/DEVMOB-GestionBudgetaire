import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/BudgetGoal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/BudgetProvider.dart';
import '../../providers/transaction_provider.dart';
import '../main_layout.dart';
import 'add_goal_page.dart';

class BudgetGoalPage extends StatefulWidget {
  const BudgetGoalPage({super.key});

  @override
  State<BudgetGoalPage> createState() => _BudgetGoalPageState();
}

class _BudgetGoalPageState extends State<BudgetGoalPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All'; // All, Active, Completed
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
      if (userId != null) {
        Provider.of<BudgetGoalProvider>(context, listen: false).init(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = Provider.of<BudgetGoalProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);
    
    // Applying Filters
    final goals = goalProvider.goals.where((goal) {
      final matchesSearch = goal.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final spentAmount = txProvider.getCategoryTotalByMonth(goal.categoryId, goal.month, goal.year);
      final isCompleted = spentAmount >= goal.targetAmount;
      final matchesMonth = goal.month == _focusedMonth.month && goal.year == _focusedMonth.year;
      
      bool matchesStatus = true;
      if (_filterStatus == 'Active') matchesStatus = !isCompleted;
      if (_filterStatus == 'Completed') matchesStatus = isCompleted;
      
      return matchesSearch && matchesStatus && matchesMonth;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // --- Custom Premium Header (Exactly like Add Goal) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Your Goals  ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  // Add Button styled like the back button
                  InkWell(
                    onTap: _navigateToAddGoal,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Color(0xFF1644FF), size: 28),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Modern Filtering Row ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(fontSize: 14, color: const Color(0xFF475569)),
                    decoration: InputDecoration(
                      hintText: 'Search your goals...',
                      hintStyle: TextStyle(color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter Chips
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...['All', 'Completed'].map((status) {
                            final isSelected = _filterStatus == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _filterStatus = status),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF1644FF) : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: isSelected ? null : Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(width: 4),
                          // Compact Month Picker
                          GestureDetector(
                            onTap: _showMonthPicker,
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_month_rounded, color: Color(0xFF1644FF), size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM yyyy').format(_focusedMonth),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- Goals List ---
            Expanded(
              child: goals.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      return _buildGoalCard(goals[index], txProvider);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BudgetGoal goal, TransactionProvider txProvider) {
    // Get real-time spending from TransactionProvider
    final double spentAmount = txProvider.getCategoryTotalByMonth(
      goal.categoryId, 
      goal.month, 
      goal.year,
    );
    
    final double progress = (spentAmount / goal.targetAmount).clamp(0.0, 1.0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              IconData(goal.iconCode, fontFamily: 'MaterialIcons'),
              color: const Color(0xFF1644FF),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      goal.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      _monthName(goal.month),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1644FF), Color(0xFF4268FF)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Amounts
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '\$${spentAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1644FF),
                              ),
                            ),
                            TextSpan(
                              text: ' spent',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${goal.targetAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.track_changes_rounded, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          Text(
            'Keep your budget on track',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set a monthly spending limit for any category',
            style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 220,
            height: 56,
            child: ElevatedButton(
              onPressed: _navigateToAddGoal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1644FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text('Add Your First Goal', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return names[(month - 1).clamp(0, 11)];
  }

  void _navigateToAddGoal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddGoalPage(initialMonth: _focusedMonth),
      ),
    );
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Select Month',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final monthIndex = index + 1;
                  final isSelected = _focusedMonth.month == monthIndex;
                  final monthName = DateFormat('MMMM').format(DateTime(2026, monthIndex));

                  return GestureDetector(
                    onTap: () {
                      setState(() => _focusedMonth = DateTime(_focusedMonth.year, monthIndex));
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1644FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          monthName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
