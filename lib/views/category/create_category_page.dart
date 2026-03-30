import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/Category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';

class CreateCategoryPage extends StatefulWidget {
  final Category? category;
  const CreateCategoryPage({super.key, this.category});

  @override
  State<CreateCategoryPage> createState() => _CreateCategoryPageState();
}

class _CreateCategoryPageState extends State<CreateCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late CategoryType _selectedType;
  late IconData _selectedIcon;
  final Color _selectedColor = const Color(0xFF1644FF);
  bool _isIconPinned = false; 

  // Extended Dictionary: monex "AI" Brain with multi-lingual support
  final Map<String, IconData> _smartIcons = {
    // Finances
    'salaire': Icons.account_balance_rounded, 'salary': Icons.account_balance_rounded, 'paye': Icons.account_balance_wallet_rounded, 
    'banque': Icons.account_balance_rounded, 'bank': Icons.account_balance_rounded, 'boulot': Icons.work_rounded, 'work': Icons.work_rounded,
    'invest': Icons.show_chart_rounded, 'bourse': Icons.trending_up_rounded, 'crypto': Icons.currency_bitcoin_rounded,

    // Food & Life
    'food': Icons.restaurant_rounded, 'restau': Icons.restaurant_rounded, 'manger': Icons.local_dining_rounded, 
    'cafe': Icons.local_cafe_rounded, 'coffee': Icons.local_cafe_rounded, 'drinks': Icons.local_bar_rounded, 
    'pizza': Icons.local_pizza_rounded, 'burger': Icons.fastfood_rounded,
    'course': Icons.shopping_basket_rounded, 'market': Icons.storefront_rounded, 'achat': Icons.shopping_bag_rounded, 'shop': Icons.shopping_cart_rounded,

    // Transport
    'voiture': Icons.directions_car_rounded, 'car': Icons.directions_car_rounded,
    'moto': Icons.electric_moped_rounded, 'bike': Icons.pedal_bike_rounded, 'velo': Icons.directions_bike_rounded,
    'taxi': Icons.local_taxi_rounded, 'uber': Icons.directions_car_filled_rounded,
    'gas': Icons.local_gas_station_rounded, 'fuel': Icons.local_gas_station_rounded, 'essence': Icons.local_gas_station_rounded,
    'trip': Icons.travel_explore_rounded, 'voyage': Icons.flight_takeoff_rounded, 'avion': Icons.flight_rounded,

    // Home & Utilities
    'loyer': Icons.add_home_rounded, 'rent': Icons.add_home_rounded, 'maison': Icons.home_rounded, 'home': Icons.home_rounded,
    'eau': Icons.water_drop_rounded, 'water': Icons.opacity_rounded,
    'elec': Icons.bolt_rounded, 'gaz': Icons.gas_meter_rounded, 'light': Icons.lightbulb_rounded,
    'inter': Icons.wifi_rounded, 'wifi': Icons.signal_wifi_4_bar_rounded, 'fibre': Icons.speed_rounded,
    'tel': Icons.phone_android_rounded, 'phone': Icons.smartphone_rounded,
    'repar': Icons.build_rounded, 'fix': Icons.handyman_rounded,

    // Health & Sport
    'med': Icons.medical_services_rounded, 'sante': Icons.health_and_safety_rounded, 'health': Icons.monitor_heart_rounded,
    'pharm': Icons.local_pharmacy_rounded, 'dent': Icons.health_and_safety_rounded,
    'gym': Icons.fitness_center_rounded, 'sport': Icons.sports_basketball_rounded, 'football': Icons.sports_soccer_rounded, 'run': Icons.directions_run_rounded,

    // Celebration & Events (User's specific Request)
    'bride': Icons.celebration_rounded, 'marriage': Icons.celebration_rounded, 'mariage': Icons.celebration_rounded,
    'fete': Icons.celebration_rounded, 'party': Icons.nightlife_rounded, 'event': Icons.event_available_rounded,
    'cine': Icons.movie_rounded, 'film': Icons.local_movies_rounded, 'netflix': Icons.subscriptions_rounded,
    'gift': Icons.redeem_rounded, 'cadeau': Icons.card_giftcard_rounded, 'present': Icons.cake_rounded,
    'anniv': Icons.cake_rounded, 'birthday': Icons.cake_rounded,

    // Personal & Pets
    'coiff': Icons.content_cut_rounded, 'barber': Icons.content_cut_rounded, 'salon': Icons.brush_rounded,
    'spa': Icons.spa_rounded, 'pet': Icons.pets_rounded, 'chien': Icons.pets_rounded, 'chat': Icons.pets_rounded,
    'help': Icons.favorite_rounded, 'charity': Icons.volunteer_activism_rounded,
  };

  @override
  void initState() {
    super.initState();
    _selectedType = widget.category?.type ?? CategoryType.expense;
    _selectedIcon = widget.category?.icon ?? Icons.category_rounded;
    
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _isIconPinned = true;
    }

    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (_isIconPinned) return;

    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      if (mounted) setState(() => _selectedIcon = Icons.category_rounded);
      return;
    }

    final name = _normalize(rawName);

    IconData? match;
    for (var entry in _smartIcons.entries) {
      if (name.contains(_normalize(entry.key))) {
        match = entry.value;
        break;
      }
    }

    if (match != null && match != _selectedIcon) {
      if (mounted) setState(() => _selectedIcon = match!);
    } else if (match == null && _selectedIcon != Icons.category_rounded) {
       if (mounted) setState(() => _selectedIcon = Icons.category_rounded);
    }
  }

  String _normalize(String text) {
    return text.toLowerCase()
      .replaceAll(RegExp(r'[àáâãäå]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceFirst('ç', 'c');
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (userId == null) return;

    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final category = Category(
      id: widget.category?.id ?? '',
      userId: userId,
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
      type: _selectedType,
    );

    try {
      if (widget.category != null) {
        await provider.updateCategory(category);
      } else {
        await provider.addCategory(category);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Custom Premium Header
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
                      Text(
                        widget.category != null ? 'Edit Category' : 'Add Category',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  // Compact Logo Signature on the right for brand touch
                  // Image.asset(
                  //   'lib/images/logo2.png',
                  //   height: 22,
                  //   errorBuilder: (context, error, stackTrace) => const SizedBox(width: 44),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Type Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _TypeCard(
                    label: 'Add Income',
                    isActive: _selectedType == CategoryType.income,
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => setState(() => _selectedType = CategoryType.income),
                  ),
                  const SizedBox(width: 16),
                  _TypeCard(
                    label: 'Add Expense',
                    isActive: _selectedType == CategoryType.expense,
                    icon: Icons.credit_card_outlined,
                    onTap: () => setState(() => _selectedType = CategoryType.expense),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Main Content Card
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category Details',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
                          decoration: InputDecoration(
                            hintText: 'Category Name',
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const SizedBox(height: 20),

                        // Icon Selection Header with AI Hint
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Select Icon', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            if (!_isIconPinned && _selectedIcon != Icons.category_rounded)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1644FF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.auto_awesome, size: 12, color: Color(0xFF1644FF)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Smart suggestion',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1644FF)),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            Icons.shopping_cart, Icons.restaurant, Icons.commute, 
                            Icons.home, Icons.movie, Icons.school,
                            Icons.medical_services, Icons.fitness_center, Icons.flight,
                            Icons.payments, Icons.subscriptions, Icons.auto_awesome_rounded // Bouton IA
                          ].map((icon) {
                            final isSelected = _selectedIcon == icon;
                            final isAIButton = icon == Icons.auto_awesome_rounded;
                            return InkWell(
                              onTap: () {
                                if (isAIButton) {
                                  _triggerAISearch();
                                } else {
                                  setState(() {
                                    _selectedIcon = icon;
                                    _isIconPinned = true; // User choice overrides AI
                                  });
                                }
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isSelected && !isAIButton ? const Color(0xFF1644FF) : 
                                         isAIButton ? const Color(0xFF1644FF).withOpacity(0.1) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isAIButton ? Border.all(color: const Color(0xFF1644FF), width: 1.5) : null,
                                ),
                                child: Icon(
                                  icon, 
                                  color: isSelected && !isAIButton ? Colors.white : 
                                         isAIButton ? const Color(0xFF1644FF) : const Color(0xFF64748B), 
                                  size: 24
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1644FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: Text(
                              widget.category != null ? 'Update Category' : 'Save Category',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerAISearch() {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrez un nom d\'abord')));
      return;
    }

    final name = _normalize(rawName);
    IconData? match;
    for (var entry in _smartIcons.entries) {
      if (name.contains(_normalize(entry.key))) {
        match = entry.value;
        break;
      }
    }

    if (match != null) {
      setState(() {
        _selectedIcon = match!;
        _isIconPinned = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Icône trouvée ! ✨'), duration: Duration(seconds: 2)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune icône spécifique, veuillez choisir manuellement'), duration: Duration(seconds: 2)));
    }
  }
}

class _TypeCard extends StatelessWidget {
  final String label;
  final bool isActive;
  final IconData icon;
  final VoidCallback onTap;

  const _TypeCard({required this.label, required this.isActive, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1644FF) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              if (!isActive)
                const BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: isActive ? Colors.white : const Color(0xFF1E293B), size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
