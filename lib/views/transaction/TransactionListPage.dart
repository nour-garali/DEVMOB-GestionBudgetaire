import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/Transaction.dart';
import 'add_transaction_page.dart';
import '../../providers/BudgetProvider.dart';

class ListTransactions extends StatefulWidget {
  const ListTransactions({super.key});

  @override
  State<ListTransactions> createState() => _ListTransactionsState();
}

class _ListTransactionsState extends State<ListTransactions>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  DateTime? _filterDate = DateTime.now(); // null means "All"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();

    // Ensure data is fetched
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      final goalProvider =
          Provider.of<BudgetGoalProvider>(context, listen: false);
      if (authProvider.user != null) {
        transactionProvider.init(authProvider.user!.uid);
        goalProvider.init(authProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final goalProvider = Provider.of<BudgetGoalProvider>(context);
    final transactions = transactionProvider.transactions;

    // Calculate total budget from goals for selected month
    final baseDate = _filterDate ?? DateTime.now();
    final totalGoalBudget = goalProvider.goals
        .where((g) => g.month == baseDate.month && g.year == baseDate.year)
        .fold(0.0, (sum, g) => sum + g.targetAmount);

    final monthlyExpenseTotal =
        transactionProvider.getMonthlyExpenseTotal(baseDate.month, baseDate.year);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                expandedHeight: 530,
                collapsedHeight: 75,
                backgroundColor: const Color(0xFFF8FAFC),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Column(
                    children: [
                      _buildAppBar(context),
                      Container(
                        color: const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          children: [
                            _buildMonthNavigator(),
                            const SizedBox(height: 10),
                            _buildExpenseCircle(
                                monthlyExpenseTotal, totalGoalBudget),
                            const SizedBox(height: 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(80),
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildTabs(),
                        // Drag Handle
                        const SizedBox(height: 4),
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Container(
            color: Colors.white,
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildCategorizedList(
                  transactions.where((t) {
                    final isType = t.type == 'income';
                    final date = _filterDate ?? DateTime.now();
                    return isType &&
                        t.date.year == date.year &&
                        t.date.month == date.month;
                  }).toList(),
                  transactionProvider,
                ),
                _buildCategorizedList(
                  transactions.where((t) {
                    final isType = t.type == 'expense';
                    final date = _filterDate ?? DateTime.now();
                    return isType &&
                        t.date.year == date.year &&
                        t.date.month == date.month;
                  }).toList(),
                  transactionProvider,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTransactionPage()),
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Color(0xFF1644FF), size: 28),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMonthNavigator() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    // Default to the currently selected filter date, or now.
    final baseDate = _filterDate ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                onTap: () => setState(() =>
                    _filterDate = DateTime(baseDate.year - 1, baseDate.month, 1)),
                child: const Icon(Icons.chevron_left_rounded,
                    color: Color(0xFF1644FF), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                baseDate.year.toString(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1644FF),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() =>
                    _filterDate = DateTime(baseDate.year + 1, baseDate.month, 1)),
                child: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF1644FF), size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Month grid � 2 rows of 6
          ...List.generate(2, (row) {
            return Padding(
              padding: EdgeInsets.only(top: row == 0 ? 0 : 10),
              child: Row(
                children: List.generate(6, (col) {
                  final index = row * 6 + col;
                  final m = index + 1;
                  final isSelected = m == baseDate.month;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _filterDate = DateTime(baseDate.year, m, 1)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1644FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            months[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
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

  Widget _buildExpenseCircle(double total, double budget) {
final percent = budget > 0
    ? ((total / budget) * 100).round()
    : 0;
    // Constant blue color for the circle
    final Color circleColor = const Color(0xFF1644FF);

    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor.withOpacity(0.05),
          ),
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
              boxShadow: [
                BoxShadow(
                  color: circleColor.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '\$${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$percent% of budget used',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          percent < 50
              ? 'Good spending control'
              : percent < 80
                  ? 'Be careful with spending'
                  : 'Budget almost exceeded',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: percent < 50
                ? const Color(0xFF16A34A)
                : percent < 80
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFF87171),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child: CustomPaint(
              painter: ArcChartPainter(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFF1644FF), 'Food'),
              const SizedBox(width: 20),
              _buildLegendItem(const Color(0xFF3B82F6), 'Rent'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFF93C5FD), 'Shopping'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.grey.withOpacity(0.05),
        indicatorColor: const Color(0xFF1644FF),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 24),
        labelColor: const Color(0xFF1E283D),
        unselectedLabelColor: const Color(0xFF94A3B8),
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        tabs: const [
          Tab(text: 'Income'),
          Tab(text: 'Expense'),
        ],
      ),
    );
  }

  Widget _buildFlatList(
      List<Transaction> transactions, TransactionProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      physics: const BouncingScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionItem(transactions[index], provider);
      },
    );
  }

  Widget _buildCategorizedList(
    List<Transaction> transactions,
    TransactionProvider provider, {
    bool shrinkWrap = false,
  }) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupTransactionsByCategory(transactions);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(24, 0, 24, shrinkWrap ? 20 : 120),
      shrinkWrap: shrinkWrap,
      primary: false,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final group = grouped[index];
        final catId = group['categoryId'] as String;
        final catName = provider.getCategoryName(catId);
        final txs = group['transactions'] as List<Transaction>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                catName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...txs.map((t) => _buildTransactionItem(t, provider)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(
      Transaction transaction, TransactionProvider provider) {
    final isIncome = transaction.type == 'income';
    final categoryName = provider.getCategoryName(transaction.categoryId);
    final categoryIcon = provider.getCategoryIcon(transaction.categoryId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              categoryIcon,
              color: const Color(0xFF1E283D),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description?.isNotEmpty == true
                      ? transaction.description!
                      : categoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E283D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(transaction.date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? "+" : "-"} \$${transaction.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E283D),
                ),
              ),
              Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _groupTransactionsByCategory(
      List<Transaction> transactions) {
    final Map<String, List<Transaction>> groups = {};
    for (final tx in transactions) {
      final cat = tx.categoryId;
      if (!groups.containsKey(cat)) groups[cat] = [];
      groups[cat]!.add(tx);
    }
    final sortedKeys = groups.keys.toList()..sort();
    return sortedKeys
        .map((key) => {'categoryId': key, 'transactions': groups[key]})
        .toList();
  }
}

class ArcChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width * 0.45;
    const strokeWidth = 26.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final circlePaint = Paint()..color = Colors.grey.withOpacity(0.15);
    canvas.drawCircle(Offset(size.width / 2, size.height - 5), 8, circlePaint);

    final rect = Rect.fromCircle(center: center, radius: radius);

    final colors = [
      const Color(0xFF1644FF), // 60%
      const Color(0xFF3B82F6), // 10%
      const Color(0xFF93C5FD), // 30%
    ];

    double startAngle = math.pi;

    // 60%
    paint.color = colors[0];
    canvas.drawArc(rect, startAngle, -0.6 * math.pi, false, paint);
    _drawText(canvas, center, radius, startAngle - 0.3 * math.pi, '60%');

    // 10%
    startAngle -= 0.6 * math.pi;
    paint.color = colors[1];
    canvas.drawArc(rect, startAngle, -0.1 * math.pi, false, paint);
    _drawText(canvas, center, radius, startAngle - 0.05 * math.pi, '10%');

    // 30%
    startAngle -= 0.1 * math.pi;
    paint.color = colors[2];
    canvas.drawArc(rect, startAngle, -0.3 * math.pi, false, paint);
    _drawText(canvas, center, radius, startAngle - 0.15 * math.pi, '30%');
  }

  void _drawText(
      Canvas canvas, Offset center, double radius, double angle, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black26,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();

    final x = center.dx + (radius * 0.6) * math.cos(angle);
    final y = center.dy + (radius * 0.6) * math.sin(angle);

    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
