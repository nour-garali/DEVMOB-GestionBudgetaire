import 'package:flutter/material.dart';
import 'dashboard/overview_page.dart';
import 'transaction/TransactionListPage.dart';
import 'settings/BudgetGoalPage.dart';
import 'category/category_page.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/BudgetProvider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  static MainLayoutState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainLayoutState>();

  @override
  MainLayoutState createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialisation des providers avec l'ID de l'utilisateur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final userId = authProvider.user!.uid;
        Provider.of<TransactionProvider>(context, listen: false).init(userId);
        Provider.of<BudgetGoalProvider>(context, listen: false).init(userId);
      }
    });
  }

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _pages = [
    const OverviewPage(),         // Index 0: Home
    const BudgetGoalPage(),      // Index 1: Goals
    const CategoryPage(),         // Index 2: Categories
    const ListTransactions(),     // Index 3: Notifications/Reports
    const SettingsView(),         // Index 4: Profile/Settings
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            const double barHeight = 70;
            const double totalHeight = 100;
            
            final List<double> xSlots = [
              width * 0.1,
              width * 0.3,
              width * 0.5,
              width * 0.7,
              width * 0.9,
            ];

            int getSlot(int itemId) {
              if (itemId == _currentIndex) return 2;
              final List<int> passiveIds = [0, 1, 2, 3, 4]..remove(_currentIndex);
              final slotMap = {
                passiveIds[0]: 0,
                passiveIds[1]: 1,
                passiveIds[2]: 3,
                passiveIds[3]: 4,
              };
              return slotMap[itemId] ?? 0;
            }

            return Container(
              height: totalHeight,
              color: Colors.transparent,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildAnimatedNavItem(0, getSlot(0), xSlots, Icons.home_outlined, Icons.home_rounded),
                  _buildAnimatedNavItem(1, getSlot(1), xSlots, Icons.fact_check_outlined, Icons.fact_check_rounded),
                  _buildAnimatedNavItem(2, getSlot(2), xSlots, Icons.category_outlined, Icons.category_rounded),
                  _buildAnimatedNavItem(3, getSlot(3), xSlots, Icons.receipt_long_outlined, Icons.receipt_long_rounded, hasNotification: true),
                  _buildAnimatedNavItem(4, getSlot(4), xSlots, Icons.settings_outlined, Icons.settings_rounded),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildAnimatedNavItem(int index, int slotIndex, List<double> slots, IconData outlined, IconData filled, {bool hasNotification = false}) {
    final bool isActive = _currentIndex == index;
    final bool isAtCenter = slotIndex == 2;
    final double x = slots[slotIndex];
    final double y = isAtCenter ? 15 : 65; 

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutQuart,
      left: x - 27,
      top: y,
      child: GestureDetector(
        onTap: () => switchTab(index),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? const Color(0xFF1644FF) : Colors.transparent,
                boxShadow: isActive ? [
                  BoxShadow(
                    color: const Color(0xFF1644FF).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ] : [],
              ),
              child: Icon(
                isActive ? filled : outlined,
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                size: 28,
              ),
            ),
            if (hasNotification && !isActive)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Compte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E283D))),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Profil',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            onTap: () {},
          ),
          const SizedBox(height: 32),
          const Text('Autre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E283D))),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Aide & Support',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'À propos',
            onTap: () {},
          ),
          const SizedBox(height: 32),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Déconnexion',
            color: Colors.red,
            onTap: () => authProvider.signOut(),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = const Color(0xFF1E283D),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
