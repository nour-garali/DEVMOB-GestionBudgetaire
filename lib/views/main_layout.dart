import 'package:flutter/material.dart';
import 'dashboard/overview_page.dart';
import 'reports/reports_page.dart';
import 'transaction/TransactionListPage.dart';
import 'settings/BudgetGoalPage.dart';
import 'category/category_page.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/BudgetProvider.dart';
import '../providers/settings_provider.dart';
import 'auth/LoginPage.dart';
import 'auth/forgot_password.dart';
import 'settings/change_password_page.dart';
import 'settings/edit_profile_page.dart';
import '../utils/photo_widget.dart';

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
    const OverviewPage(),
    const BudgetGoalPage(),
    const CategoryPage(),
    const ListTransactions(),
    const SettingsView(),
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
                  _buildAnimatedNavItem(4, getSlot(4), xSlots, Icons.person_outline_rounded, Icons.person_rounded),
                ],
              ),
            );
          },
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
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1644FF).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
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

// ════════════════════════════════════════════════════════════════════════════
// SETTINGS VIEW
// ════════════════════════════════════════════════════════════════════════════

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final user = authProvider.user;
    final bool isDark = settings.isDarkMode;
    final bool hideBal = settings.hideBalances;
    final String lang = settings.language;

    // Basic localization map
    final Map<String, Map<String, String>> local = {
      'Français': {
        'profile': 'Profil',
        'edit': 'Modifier le profil',
        'password': 'Mot de passe',
        'lang': 'Langue',
        'appearance': 'Apparence',
        'dark': 'Mode Sombre',
        'hide': 'Masquer les montants',
        'logout': 'Se déconnecter',
        'personal': 'Compte personnel',
        'search': 'Rechercher',
      },
      'English': {
        'profile': 'Profile',
        'edit': 'Edit Profile',
        'password': 'Password',
        'lang': 'Language',
        'appearance': 'Appearance',
        'dark': 'Dark Mode',
        'hide': 'Hide Balances',
        'logout': 'Log out',
        'personal': 'Personal account',
        'search': 'Search',
      },
      'العربية': {
        'profile': 'الملف الشخصي',
        'edit': 'تعديل الملف الشخصي',
        'password': 'كلمة المرور',
        'lang': 'اللغة',
        'appearance': 'المظهر',
        'dark': 'الوضع الداكن',
        'hide': 'إخفاء المبالغ',
        'logout': 'تسجيل الخروج',
        'personal': 'حساب شخصي',
        'search': 'بحث',
      }
    };

    final t = local[lang] ?? local['English']!;

    final String displayName = user?.name ?? 'User Name';
    final String initials = displayName.trim().split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFBFDFF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 12),
            
            // --- Top App Bar Style ---
            Row(
              children: [
                IconButton(
                  onPressed: () {}, // Simulated back or menu
                  icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // --- Profile Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t['personal']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD6EBFF),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                            ? ProfilePhoto(
                                photoUrl: user.photoUrl!,
                                fallback: _buildInitialsAvatar(initials, size: 24),
                              )
                            : _buildInitialsAvatar(initials, size: 24),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16B9FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- Search Bar ---
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {}),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: t['search'],
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                  suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ) 
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- Filter Logic ---
            ...(() {
              final String query = _searchController.text.toLowerCase();
              bool matches(String text) => text.toLowerCase().contains(query);

              // 1. Profile Section
              final List<Widget> profileItems = [];
              if (matches(t['edit']!)) {
                profileItems.add(_buildMenuItem(
                  icon: Icons.person_outline_rounded,
                  label: t['edit']!,
                  isDark: isDark,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
                ));
              }
              if (matches(t['password']!)) {
                if (profileItems.isNotEmpty) profileItems.add(_buildDivider(isDark));
                profileItems.add(_buildMenuItem(
                  icon: Icons.lock_outline_rounded,
                  label: t['password']!,
                  isDark: isDark,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage())),
                ));
              }
              if (matches(t['lang']!)) {
                if (profileItems.isNotEmpty) profileItems.add(_buildDivider(isDark));
                profileItems.add(_buildMenuItem(
                  icon: Icons.translate_rounded,
                  label: t['lang']!,
                  isDark: isDark,
                  trailing: Text(
                    settings.language,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                  onTap: () => _showLanguagePicker(context, settings),
                ));
              }

              // 2. Appearance Section
              final List<Widget> appItems = [];
              if (matches(t['dark']!)) {
                appItems.add(_buildMenuItem(
                  icon: Icons.palette_outlined,
                  label: t['dark']!,
                  isDark: isDark,
                  trailing: Switch(
                    value: isDark,
                    onChanged: (val) => settings.toggleTheme(),
                    activeColor: const Color(0xFF16B9FF),
                    activeTrackColor: const Color(0xFF16B9FF).withOpacity(0.3),
                  ),
                ));
              }
              if (matches(t['hide']!)) {
                if (appItems.isNotEmpty) appItems.add(_buildDivider(isDark));
                appItems.add(_buildMenuItem(
                  icon: Icons.visibility_off_outlined,
                  label: t['hide']!,
                  isDark: isDark,
                  trailing: Switch(
                    value: hideBal,
                    onChanged: (val) => settings.toggleHideBalances(),
                    activeColor: const Color(0xFF16B9FF),
                    activeTrackColor: const Color(0xFF16B9FF).withOpacity(0.3),
                  ),
                ));
              }

              final List<Widget> results = [];
              if (profileItems.isNotEmpty) {
                results.add(_sectionHeader(t['profile']!, isDark));
                results.add(const SizedBox(height: 12));
                results.add(_buildCard(isDark: isDark, items: profileItems));
                results.add(const SizedBox(height: 24));
              }
              if (appItems.isNotEmpty) {
                results.add(_sectionHeader(t['appearance']!, isDark));
                results.add(const SizedBox(height: 12));
                results.add(_buildCard(isDark: isDark, items: appItems));
                results.add(const SizedBox(height: 24));
              }
              
              if (results.isEmpty && query.isNotEmpty) {
                return [
                  const SizedBox(height: 40),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Color(0xFF94A3B8)),
                        SizedBox(height: 16),
                        Text('No matches found', 
                          style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                ];
              }

              return results;
            })(),

            const SizedBox(height: 32),

            // --- Sign Out ---
            GestureDetector(
              onTap: () async {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1644FF).withOpacity(0.1) : const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: Color(0xFF1644FF), size: 22),
                    const SizedBox(width: 12),
                    Text(
                      t['logout']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1644FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 120), // Bottom nav space
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildCard({required bool isDark, required List<Widget> items}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            if (trailing != null) trailing else const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials, {double size = 30}) {
    return Container(
      color: const Color(0xFFD6EBFF),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: const Color(0xFF1644FF),
            fontWeight: FontWeight.bold,
            fontSize: size,
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider settings) {
    final bool isDark = settings.isDarkMode;
    final List<String> languages = ['Français', 'العربية', 'English'];
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Language',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            ...languages.map((l) => GestureDetector(
              onTap: () {
                settings.setLanguage(l);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: settings.language == l 
                    ? const Color(0xFF1644FF) 
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(l, style: TextStyle(
                      color: settings.language == l ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    )),
                    const Spacer(),
                    if (settings.language == l) const Icon(Icons.check_circle, color: Colors.white),
                  ],
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
