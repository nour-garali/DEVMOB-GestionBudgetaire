import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/Category.dart';
import '../../models/Transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/BudgetProvider.dart';
import 'package:intl/intl.dart';
import '../category/create_category_page.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  String _transactionType = 'expense'; // 'income' or 'expense'

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1644FF),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1644FF),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }

    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (userId == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;

    // Budget check logic for expenses
    if (_transactionType == 'expense') {
      final savingsProvider = Provider.of<BudgetGoalProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

      final matchingGoals = savingsProvider.goals.where(
        (g) => g.categoryId == _selectedCategory!.id && g.month == _selectedDate.month && g.year == _selectedDate.year,
      );
      
      if (matchingGoals.isNotEmpty) {
        final goal = matchingGoals.first;
        if (goal.targetAmount > 0) {
          final currentSpent = transactionProvider.getCategoryTotalByMonth(
            _selectedCategory!.id,
            _selectedDate.month,
            _selectedDate.year,
          );

          if (currentSpent + amount > goal.targetAmount) {
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Budget Exceeded'),
                content: const Text(
                  'You are about to exceed your monthly budget for this category.\nDo you want to continue?'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Continue', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (shouldContinue != true) {
              return; // Stop saving if user doesn't confirm
            }
          }
        }
      }
    }

    final transaction = Transaction(
      id: '',
      userId: userId,
      amount: amount,
      categoryId: _selectedCategory!.id,
      date: _selectedDate,
      description: _descriptionController.text.trim(),
      type: _transactionType,
    );

    try {
      await Provider.of<TransactionProvider>(context, listen: false).addTransaction(transaction);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final isExpense = _transactionType == 'expense';
    
    final filteredCategories = transactionProvider.categories
        .where((c) => c.type == (isExpense ? CategoryType.expense : CategoryType.income))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Color(0xFF1E293B)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          isExpense ? 'Add Expense' : 'Add Income',
          style: TextStyle(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // --- Expense / income Toggle ---
                  _buildTypeToggle(),

                  const SizedBox(height: 24),
                  
                  // --- Horizontal Calendar Card ---
                  _buildHorizontalCalendar(),
                  
                  const SizedBox(height: 32),

                  // --- Title Input ---
                  _buildLabel(_transactionType == 'expense' ? 'Expense Title' : 'income Title'),
                  const SizedBox(height: 12),
                  _buildTextField(_descriptionController, 'Side Business'),

                  const SizedBox(height: 24),

                  // --- Amount Input ---
                  _buildLabel('Amount'),
                  const SizedBox(height: 12),
                  _buildTextField(_amountController, '1,368', isAmount: true),

                  const SizedBox(height: 24),

                  // --- Category Selection ---
                  _buildLabel(_transactionType == 'expense' ? 'Expense Category' : 'income Category'),
                  const SizedBox(height: 12),
                  _buildCategoryBubbles(filteredCategories),

                  const SizedBox(height: 120), // Space for fab button
                ],
              ),
            ),
          ),
          
          // --- Sticky Bottom Button ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildSubmitButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    final isExpense = _transactionType == 'expense';
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Animated Pill Background
          AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            alignment: isExpense ? Alignment.centerLeft : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Toggle Labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _transactionType = 'expense'),
                  child: Center(
                    child: Text(
                      'Expense',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isExpense ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _transactionType = 'income'),
                  child: Center(
                    child: Text(
                      'Income',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: !isExpense ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildHorizontalCalendar() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Month/Year header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircularArrow(Icons.chevron_left, () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 7)))),
                  Text(
                    DateFormat('MMMM - yyyy', 'fr_FR').format(_selectedDate),
                    style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                  _buildCircularArrow(Icons.chevron_right, () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 7)))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Days row (Expanded évite l'overflow sur petits écrans)
            Row(
              children: List.generate(7, (index) {
                final date = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1 - index));
                final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
                final dayName = DateFormat('E', 'en_US').format(date);
                
                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final side = c.maxWidth < 48 ? c.maxWidth : 48.0;
                            return Container(
                              width: side,
                              height: side,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF1644FF) : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: side < 44 ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Icon(icon, color: const Color(0xFF334155), size: 20),
      ),
    );
  }

  Widget _buildCategoryBubbles(List<Category> categories) {
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add button with custom dashed painter
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateCategoryPage())),
            child: CustomPaint(
              painter: DashedCirclePainter(color: const Color(0xFFCBD5E1)),
              child: const SizedBox(
                width: 64,
                height: 64,
                child: Icon(Icons.add, color: Color(0xFF94A3B8), size: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Categories
          ...categories.map((c) {
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
          }),
        ],
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
        onPressed: _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1644FF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          (_transactionType == 'expense' ? 'ADD EXPENSE' : 'ADD INCOME'),
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 18),
        ),
      ),
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double dashWidth = 5, dashSpace = 3;
    final double radius = size.width / 2;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double circumference = 2 * 3.141592653589793 * radius;
    final double totalDashLength = dashWidth + dashSpace;
    final int dashCount = (circumference / totalDashLength).floor();

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * totalDashLength) / circumference * 2 * 3.141592653589793;
      final double sweepAngle = dashWidth / circumference * 2 * 3.141592653589793;
      canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
