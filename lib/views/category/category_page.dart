import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/category_card.dart';
import '../../models/Category.dart';
import 'create_category_page.dart';
import '../../providers/auth_provider.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  CategoryType? _filterType;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Category> categories) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.addAll(categories.map((c) => c.id));
    });
  }

  Future<void> _deleteSelected() async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Delete ${_selectedIds.length} categories and their transactions?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      for (var id in _selectedIds) {
        await provider.deleteCategory(userId, id);
      }
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> _deleteAll(List<Category> categories) async {
    if (categories.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer TOUT'),
        content: Text('Voulez-vous supprimer ABSOLUMENT toutes les ${categories.length} catégories et TOUTES leurs transactions ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OUI, TOUT SUPPRIMER', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
      if (userId == null) return;

      await provider.deleteAllCategories(userId);
      
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final currentList = _filterType == null 
      ? provider.categories 
      : provider.categories.where((c) => c.type == _filterType).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      bottomSheet: _isSelectionMode ? _buildSelectionActions() : null,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              });
            }
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
              
              // --- Page Title & Add Button ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isSelectionMode ? '${_selectedIds.length} Selected' : 'Categories',
                      style: TextStyle(
                        fontSize: _isSelectionMode ? 22 : 28,
                        fontWeight: FontWeight.w900,
                        color: _isSelectionMode ? const Color(0xFF1644FF) : const Color(0xFF0F172A),
                        letterSpacing: -1,
                      ),
                    ),
                    _isSelectionMode 
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 28),
                          onPressed: () => setState(() { _isSelectionMode = false; _selectedIds.clear(); }),
                        )
                      : IconButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateCategoryPage())),
                          icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF1644FF), size: 32),
                        ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // --- Horizontal Balance Cards ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _StatCard(
                      title: 'Total Income',
                      amount: '${provider.totalIncome.toStringAsFixed(2)} DT',
                      icon: Icons.account_balance_wallet_outlined,
                      isPrimary: false,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      title: 'Total Expense',
                      amount: '${provider.totalExpense.toStringAsFixed(2)} DT',
                      icon: Icons.account_balance_wallet_outlined,
                      isPrimary: true,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      title: 'Balance',
                      amount: '${provider.balance.toStringAsFixed(2)} DT',
                      icon: Icons.account_balance_wallet_outlined,
                      isPrimary: false,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // --- Action Chips / Filters ---
              Row(
                children: [
                  _ActionChip(
                    icon: Icons.apps_rounded,
                    label: 'All',
                    isSelected: _filterType == null,
                    onTap: () => setState(() => _filterType = null),
                  ),
                  const SizedBox(width: 12),
                  _ActionChip(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Income',
                    isSelected: _filterType == CategoryType.income,
                    onTap: () => setState(() => _filterType = CategoryType.income),
                  ),
                  const SizedBox(width: 12),
                  _ActionChip(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Expense',
                    isSelected: _filterType == CategoryType.expense,
                    onTap: () => setState(() => _filterType = CategoryType.expense),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // --- Dynamic Filter Indicator ---
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    bool isActive = false;
                    if (index == 0 && _filterType == null) isActive = true;
                    if (index == 1 && _filterType == CategoryType.income) isActive = true;
                    if (index == 2 && _filterType == CategoryType.expense) isActive = true;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutBack,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: isActive ? 16 : 8,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF1644FF) : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // --- "My Categories" Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E283D),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'select') setState(() => _isSelectionMode = true);
                      if (val == 'delete_all') await _deleteAll(provider.categories);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'select', child: Text('Sélectionner')),
                      const PopupMenuItem(
                        value: 'delete_all', 
                        child: Text('Supprimer tout', style: TextStyle(color: Colors.red))
                      ),
                    ],
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.more_horiz_rounded, color: Color(0xFF1E283D)),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              // --- List Area ---
              provider.isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                  : currentList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: currentList.length,
                          itemBuilder: (context, index) {
                            final category = currentList[index];
                            final categoryTotal = provider.getCategoryMonthlyTotal(category.id);
                            
                            return CategoryCard(
                              category: category,
                              subtitle: DateFormat('MMMM yyyy').format(DateTime.now()), 
                              amount: categoryTotal,
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedIds.contains(category.id),
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(category.id);
                                } else {
                                  // Normal tap
                                }
                              },
                              onEdit: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => CreateCategoryPage(category: category)));
                              },
                              onDelete: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirm deletion'),
                                    content: Text('Do you want to delete the category"${category.name}" and all its associated transactions?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
                                  if (userId != null) {
                                    await provider.deleteCategory(userId, category.id);
                                  }
                                }
                              },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

  Widget _buildSelectionActions() {
    final count = _selectedIds.length;
    final canEdit = count == 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _deleteSelected,
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
                if (canEdit) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final provider = Provider.of<TransactionProvider>(context, listen: false);
                        final cat = provider.categories.firstWhere((c) => c.id == _selectedIds.first);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CreateCategoryPage(category: cat)));
                      },
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1644FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.category_outlined, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text(
            'Aucune catégorie trouvée', 
            style: TextStyle(color: Color(0xFF8B92A5), fontWeight: FontWeight.w600)
          ),
        ],
      ),
    );
  }
}

// --- Internal Helper Widgets matching the image ---

class _StatCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final bool isPrimary;

  const _StatCard({required this.title, required this.amount, required this.icon, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF1644FF) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF0F172A), size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isPrimary ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isPrimary ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1644FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF1644FF).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF1E293B), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
