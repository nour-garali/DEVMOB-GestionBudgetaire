import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/BudgetGoal.dart';
import '../../models/Category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/BudgetProvider.dart';
import '../../providers/transaction_provider.dart';

class AddGoalPage extends StatefulWidget {
  final DateTime? initialMonth;
  const AddGoalPage({super.key, this.initialMonth});

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  late DateTime _selectedMonth;
  Category? _selectedCategory;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Default to September as requested before, OR the passed initialMonth
    _selectedMonth = widget.initialMonth ?? DateTime(DateTime.now().year, 9);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    if (amount > 0 && userId != null) {
      await Provider.of<BudgetGoalProvider>(context, listen: false).addGoal(BudgetGoal(
        id: '',
        userId: userId,
        name: _selectedCategory!.name,
        categoryId: _selectedCategory!.id,
        currentAmount: 0.0,
        targetAmount: amount,
        iconCode: _selectedCategory!.icon.codePoint,
        month: _selectedMonth.month,
        year: _selectedMonth.year,
      ));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final expenseCategories = transactionProvider.categories
        .where((c) => c.type == CategoryType.expense)
        .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // --- Custom Premium Header (Exactly like Add Category) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
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
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Add Goal',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  // Image.asset(
                  //   'lib/images/logo2.png',
                  //   height: 22,
                  //   errorBuilder: (context, error, stackTrace) => const SizedBox(width: 44),
                  // ),
                ],
              ),
            ),
            // l'espacement entre le app bar et le body
            const SizedBox(height: 40),

            // --- Scrollable Content ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Month Selector Card ──
                      _buildMonthSelectorCard(),
                      
                      const SizedBox(height: 34),

                      // ── Category Selection with Search ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLabel('Goal Category'),
                          if (expenseCategories.length > 4 || _searchQuery.isNotEmpty)
                            SizedBox(
                              width: 140,
                              height: 38,
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) => setState(() => _searchQuery = val),
                                style: TextStyle(fontSize: 13, color: const Color(0xFF475569)),
                                decoration: InputDecoration(
                                  hintText: 'Rechercher...',
                                  hintStyle: TextStyle(color: const Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryBubbles(expenseCategories),

                      const SizedBox(height: 34),

                      // ── Maximum Amount Input ──
                      _buildLabel('Maximum Amount'),
                      const SizedBox(height: 12),
                      _buildTextField(_amountController, 'Ex: 500', isAmount: true),

                      const SizedBox(height: 120), // Space for fab button
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // --- Sticky Bottom Button ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildSubmitButton(),
      ),
    );
  }

  Widget _buildMonthSelectorCard() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year - 1, _selectedMonth.month)),
                child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1644FF), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                _selectedMonth.year.toString(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1644FF),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year + 1, _selectedMonth.month)),
                child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF1644FF), size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Month grid — 2 rows of 6
          ...List.generate(2, (row) {
            return Padding(
              padding: EdgeInsets.only(top: row == 0 ? 0 : 10),
              child: Row(
                children: List.generate(6, (col) {
                  final index = row * 6 + col;
                  final m = index + 1;
                  final isSelected = m == _selectedMonth.month;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, m)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1644FF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            months[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: const Color(0xFF94A3B8), 
        fontWeight: FontWeight.w600, 
        fontSize: 16
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isAmount = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isAmount ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: const Color(0xFF475569)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFF64748B), fontWeight: FontWeight.normal),
        suffixIcon: isAmount ? Container(
          padding: const EdgeInsets.only(right: 20),
          width: 0, 
          alignment: Alignment.centerRight,
          child: Text('\$', style: TextStyle(color: const Color(0xFFCBD5E1), fontSize: 20, fontWeight: FontWeight.bold))
        ) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
      ),
    );
  }

  Widget _buildCategoryBubbles(List<Category> categories) {
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.map((c) {
          final isSelected = _selectedCategory?.id == c.id;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1644FF) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? const Color(0xFF1644FF).withOpacity(0.3) : Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      c.icon,
                      size: 20,
                      color: isSelected ? Colors.white : const Color(0xFF1644FF),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      c.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1644FF).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1644FF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text(
          'Add Goal',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
