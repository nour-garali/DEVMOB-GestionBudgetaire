import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

// Enum pour gérer les 3 états de la page
enum ResetState { inputEmail, waitingEmail, success }

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  ResetState _state = ResetState.inputEmail;

  // Animations pour la page d'attente
  late AnimationController _pulseController;
  late AnimationController _dotController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _dotAnimation;

  // Animations pour la page succès
  late AnimationController _successController;
  late Animation<double> _successScaleAnim;
  late Animation<double> _successFadeAnim;

  Timer? _resendTimer;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _dotAnimation = Tween<double>(begin: 0, end: 1).animate(_dotController);

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _successScaleAnim = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _successFadeAnim = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotController.dispose();
    _successController.dispose();
    _resendTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendPasswordResetEmail(
      _emailController.text.trim(),
    );
    if (success && mounted) {
      setState(() => _state = ResetState.waitingEmail);
      _startResendCooldown();
    }
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.sendPasswordResetEmail(_emailController.text.trim());
    if (mounted) _startResendCooldown();
  }

  void _confirmPasswordChanged() {
    setState(() => _state = ResetState.success);
    _successController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _state == ResetState.inputEmail
              ? _buildInputView(authProvider)
              : _state == ResetState.waitingEmail
                  ? _buildWaitingView()
                  : _buildSuccessView(),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  // VUE 1 — Saisie de l'email
  // ════════════════════════════════════════════════
  Widget _buildInputView(AuthProvider authProvider) {
    return SingleChildScrollView(
      key: const ValueKey('input'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E283D)),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Forgot Your\nPassword ?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E283D),
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter your email address below and we\'ll send you a link to reset your password.',
            style: TextStyle(fontSize: 15, color: Color(0xFF8B92A5), height: 1.5),
          ),
          const SizedBox(height: 48),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 15, color: Color(0xFF1E283D)),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter your email';
                if (!val.contains('@')) return 'Invalid email format';
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Email Address',
                hintStyle: const TextStyle(color: Color(0xFFB0B7C3), fontSize: 15),
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1E283D), size: 20),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1644FF), width: 1.5)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (authProvider.errorMessage != null) ...[
            Text(authProvider.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: const Color(0xFF1644FF).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : _handleReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1644FF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF1644FF).withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SEND RESET LINK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // VUE 2 — Page d'attente animée
  // ════════════════════════════════════════════════
  Widget _buildWaitingView() {
    return Padding(
      key: const ValueKey('waiting'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => setState(() => _state = ResetState.inputEmail),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE5E7EB))),
                child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E283D)),
              ),
            ),
          ),
          const Spacer(),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1644FF).withOpacity(0.12), const Color(0xFF1644FF).withOpacity(0.06)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_unread_rounded, size: 56, color: Color(0xFF1644FF)),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _dotAnimation,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final delay = i / 3;
                  final val = (_dotAnimation.value - delay).clamp(0.0, 1.0);
                  final opacity = (val < 0.5 ? val * 2 : (1 - val) * 2).clamp(0.3, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1644FF), shape: BoxShape.circle)),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text('Check your email', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1E283D)), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 15, color: Color(0xFF8B92A5), height: 1.6),
              children: [
                const TextSpan(text: 'We\'ve sent a password reset link to\n'),
                TextSpan(text: _emailController.text.trim(), style: const TextStyle(color: Color(0xFF1644FF), fontWeight: FontWeight.w600)),
                const TextSpan(text: '\n\nClick the link in your email, then come back here.'),
              ],
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: const Color(0xFF1644FF).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: ElevatedButton(
                onPressed: _confirmPasswordChanged,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1644FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('I\'VE RESET MY PASSWORD', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _resendCooldown > 0 ? null : _resendEmail,
            child: AnimatedOpacity(
              opacity: _resendCooldown > 0 ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                _resendCooldown > 0 ? 'Resend email in ${_resendCooldown}s' : 'Didn\'t receive it? Resend email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _resendCooldown > 0 ? const Color(0xFF8B92A5) : const Color(0xFF1644FF),
                ),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // VUE 3 — Succès (même design que l'interface précédente)
  // ════════════════════════════════════════════════
  Widget _buildSuccessView() {
    return Padding(
      key: const ValueKey('success'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E283D)),
              ),
            ),
          ),

          const Spacer(),

          // ── Illustration téléphone + checkmark (design original) ──
          ScaleTransition(
            scale: _successScaleAnim,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cercle gris de fond
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDF1F7),
                    shape: BoxShape.circle,
                  ),
                ),
                // Rectangle téléphone (outline bleu)
                Container(
                  width: 70,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF1644FF), width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Points colorés décoratifs
                Positioned(top: 30, right: 20, child: Icon(Icons.circle, size: 4, color: Colors.green[400])),
                Positioned(bottom: 40, left: 20, child: Icon(Icons.circle, size: 4, color: Colors.red[400])),
                Positioned(top: 40, left: 20, child: Icon(Icons.circle, size: 4, color: Colors.orange[400])),
                // Badge checkmark
                Positioned(
                  bottom: 30,
                  right: -10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0xFF1644FF), shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 8),
                        const Text('****', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E283D), letterSpacing: 2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          FadeTransition(
            opacity: _successFadeAnim,
            child: Column(
              children: [
                const Text(
                  'Password updated!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1E283D)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your password has been setup successfully',
                  style: TextStyle(fontSize: 16, color: Color(0xFF8B92A5)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bouton BACK TO LOGIN
          SizedBox(
            width: double.infinity,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF1644FF).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1644FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('BACK TO LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
