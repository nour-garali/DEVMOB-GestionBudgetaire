import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../main_layout.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // États de validation du mot de passe
  bool _hasMinLength = false;
  bool _hasSymbolOrNumber = false;
  bool _doesNotContainNameOrEmail = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _nameController.addListener(_validatePassword);
    _emailController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final pass = _passwordController.text;
    final name = _nameController.text.toLowerCase();
    final email = _emailController.text.toLowerCase();

    setState(() {
      _hasMinLength = pass.length >= 8;
      _hasSymbolOrNumber = pass.contains(RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]'));

      if (pass.isEmpty) {
        _doesNotContainNameOrEmail = false;
      } else {
        bool containsName = name.isNotEmpty && pass.toLowerCase().contains(name);
        bool containsEmailHead = email.isNotEmpty && pass.toLowerCase().contains(email.split('@')[0]);
        _doesNotContainNameOrEmail = !containsName && !containsEmailHead;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (mounted && success == true) {
      // Firebase connecte automatiquement l'utilisateur après l'inscription
      // Nous le déconnectons pour le forcer à se connecter manuellement
      await authProvider.signOut();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please log in'),
            backgroundColor: Color(0xFF1644FF),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Redirige vers la page de Login (qui a ouvert la page Register)
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── HEADER SECTION (Logo Centré) ──
                  // J'utilise une icône Flutter standard pour simuler le logo si vous n'avez pas l'image chargée
                  // Remplacez Icon par Image.asset('lib/images/logo2.png', height: 60)
                  Image.asset(
                    'lib/images/logo2.png', 
                    height: 60,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.layers, size: 60, color: Color(0xFF1D4ED8)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'monex',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── LES CHAMPS DE SAISIE ──
                  _buildField(
                    controller: _nameController,
                    hint: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _emailController,
                    hint: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Please enter your email';
                      if (!val.contains('@')) return 'Invalid email format';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: !_showPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: const Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Please enter a password' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm Password',
                    icon: Icons.lock_outline,
                    obscureText: !_showConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: const Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Please confirm your password';
                      if (val != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── EXIGENCES DU MOT DE PASSE (Discret) ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      children: [
                        _requirementRow('Must not contain your name or email', _doesNotContainNameOrEmail),
                        const SizedBox(height: 6),
                        _requirementRow('At least 8 characters', _hasMinLength),
                        const SizedBox(height: 6),
                        _requirementRow('Contains a symbol or a number', _hasSymbolOrNumber),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── BOUTON D'INSCRIPTION ──
                  if (authProvider.errorMessage != null) ...[
                    Text(
                      authProvider.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1644FF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF1644FF).withOpacity(0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: const Color(0xFF1644FF).withOpacity(0.3),
                      ).copyWith(
                        elevation: WidgetStateProperty.all(8),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'REGISTER',
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold, 
                                letterSpacing: 1.2
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── LIEN VERS CONNEXION ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ", 
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Login here', 
                          style: TextStyle(
                            color: Color(0xFF1D4ED8), 
                            fontWeight: FontWeight.w700, 
                            fontSize: 14
                          )
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget Helper pour les champs stylisés "Monex"
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(icon, color: const Color(0xFF9CA3AF), size: 22),
        ),
        suffixIcon: suffixIcon != null 
            ? Padding(padding: const EdgeInsets.only(right: 8), child: suffixIcon) 
            : null,
        filled: true,
        fillColor: const Color(0xFFF6F7F9), // Gris très clair pour le fond
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        // Bordures totalement arrondies (forme pilule) et sans ligne visible
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), 
          borderSide: BorderSide.none
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), 
          borderSide: BorderSide.none
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), 
          borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5)
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), 
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.0)
        ),
      ),
    );
  }

  // Widget Helper pour les exigences mot de passe
  Widget _requirementRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: isMet ? const Color(0xFF1D4ED8) : const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? const Color(0xFF1E293B) : const Color(0xFF9CA3AF),
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}