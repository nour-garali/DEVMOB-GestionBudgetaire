import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/photo_widget.dart';
import '../reports/reports_page.dart';
import '../transaction/TransactionListPage.dart';
import '../main_layout.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late DateTime _selectedDate;
  late ScrollController _dateScrollController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateScrollController = ScrollController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateScrollController.hasClients) {
        // Un petit délai pour que la liste soit bien rendue avant le scroll
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToSelectedDate();
        });
      }
    });
  }

  void _scrollToSelectedDate() {
    if (!_dateScrollController.hasClients) return;
    final index = _selectedDate.day - 1;
    // La largeur d'un élément date est d'environ 60px.
    double offset = (index * 60.0) - (MediaQuery.of(context).size.width / 2) + 30.0;
    if (offset < 0) offset = 0;
    if (offset > _dateScrollController.position.maxScrollExtent) {
      offset = _dateScrollController.position.maxScrollExtent;
    }
    _dateScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  List<DateTime> get _monthDays {
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final lastDay = DateTime(year, month + 1, 0).day;
    return List.generate(lastDay, (index) => DateTime(year, month, index + 1));
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + offset, 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final userName = authProvider.user?.name ?? 'Utilisateur';

    final bool hideBal = settingsProvider.hideBalances;

    // Image colors palette:
    const bgColor = Color(0xFFF6F7F9);
    const textDark = Color(0xFF1E1E1E);
    const textGrey = Color(0xFF9095A1);
    const primarySoftBlue = Color(0xFFE0E7FF); // Replacing green with soft pastel blue
    const primaryBlue = Color(0xFF1644FF); // Replacing bright green with primary blue
    const white = Colors.white;

    // Filter transactions for the selected date
    final dailyTransactions = transactionProvider.transactions.where((t) {
      return t.date.year == _selectedDate.year &&
             t.date.month == _selectedDate.month &&
             t.date.day == _selectedDate.day;
    }).toList();
    
    dailyTransactions.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFE5E7EB),
                        backgroundImage: photoProvider(authProvider.user?.photoUrl),
                        child: photoProvider(authProvider.user?.photoUrl) == null
                            ? const Icon(Icons.person, color: textGrey)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good morning!',
                            style: TextStyle(
                              color: textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTopIconButton(Icons.bar_chart_rounded, onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReportsPage()),
                        );
                      }),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // --- MAIN GREEN CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: BoxDecoration(
                  color: primarySoftBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white60,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.flash_on_rounded, size: 14, color: textDark),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Total Balance',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1644FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            hideBal 
                                ? '•••••• DT'
                                : '${transactionProvider.balance.toStringAsFixed(0)} DT',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                              height: 1.1,
                              letterSpacing: -1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Right Circular Progress
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: 0.75, // Arbitrary progress like the image "6 days"
                            strokeWidth: 12,
                            backgroundColor: Colors.white,
                            valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
                            strokeCap: StrokeCap.round,
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  transactionProvider.transactions.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: textDark,
                                    height: 1.0,
                                  ),
                                ),
                                const Text(
                                  'trans.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1644FF), // primary blue
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- TWO SQUARE CARDS ---
              Row(
                children: [
                  Expanded(
                    child: _buildSquareCard(
                      title: 'Income',
                      value: hideBal ? '••••' : transactionProvider.totalIncome.toStringAsFixed(0),
                      unit: 'DT',
                      icon: Icons.south_west_rounded,
                      iconBgColor: const Color(0xFFFFF1EB), // Light orange
                      iconColor: const Color(0xFFFF7A00),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSquareCard(
                      title: 'Expense',
                      value: hideBal ? '••••' : transactionProvider.totalExpense.toStringAsFixed(0),
                      unit: 'DT',
                      icon: Icons.water_drop_rounded, // Like image "drink water"
                      iconBgColor: const Color(0xFFE8F5FF), // Light blue
                      iconColor: const Color(0xFF0094FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- DATE HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      _buildDateArrowButton(Icons.arrow_back_rounded, () => _changeMonth(-1)),
                      const SizedBox(width: 8),
                      _buildDateArrowButton(Icons.arrow_forward_rounded, () => _changeMonth(1)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- DATES CAROUSEL ---
              SizedBox(
                height: 85,
                child: ListView.builder(
                  controller: _dateScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _monthDays.length,
                  itemBuilder: (context, index) {
                    final date = _monthDays[index];
                    final isSelected = date.day == _selectedDate.day;
                    final dayLetter = DateFormat('E').format(date).substring(0, 1);
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedDate = date);
                        _scrollToSelectedDate();
                      },
                      child: Container(
                        width: 50,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? primarySoftBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayLetter,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? textDark : textGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('dd').format(date),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? textDark : textDark.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 32),
              
              // --- RECENT TRANSACTIONS HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      MainLayout.of(context)?.switchTab(3);
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- TRANSACTIONS LIST ---
              (() {
                final recentTransactions = transactionProvider.transactions.toList();
                recentTransactions.sort((a, b) => b.date.compareTo(a.date));
                final displayList = recentTransactions.take(5).toList();

                if (displayList.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No transactions yet',
                        style: TextStyle(color: textGrey, fontWeight: FontWeight.w500),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final tx = displayList[index];
                    final isIncome = tx.type == 'income';
                    final categoryName = transactionProvider.getCategoryName(tx.categoryId);
                    final categoryIcon = transactionProvider.getCategoryIcon(tx.categoryId);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isIncome ? const Color(0xFFFFF1EB) : const Color(0xFFFEF3F2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        categoryIcon,
                                        size: 14,
                                        color: isIncome ? const Color(0xFFFF7A00) : const Color(0xFFF95B51),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      hideBal 
                                          ? '•••• DT'
                                          : '${isIncome ? '+' : '-'} ${tx.amount.toStringAsFixed(0)} DT',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Arrow indicator
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isIncome ? const Color(0xFFD1FADF) : const Color(0xFFFEE4E2),
                              border: Border.all(color: white, width: 2),
                            ),
                            child: Icon(
                              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              size: 14,
                              color: isIncome ? const Color(0xFF039855) : const Color(0xFFD92D20),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              })(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: const Color(0xFF1E1E1E), size: 22),
        ),
      ),
    );
  }

  Widget _buildDateArrowButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF8B929A), size: 18),
      ),
    );
  }

  Widget _buildSquareCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                  height: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  value.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E1E),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}