import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
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
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _emailSent ? _buildSuccessView() : _buildInputView(authProvider),
        ),
      ),
    );
  }

  Widget _buildInputView(AuthProvider authProvider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // ── Back Button ───────────────────────────────────────
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
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF8B92A5),
              height: 1.5,
            ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1644FF), width: 1.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1644FF).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : _handleReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1644FF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF1644FF).withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'SEND RESET LINK',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const SizedBox(height: 16),
        
        // ── Back Button ───────────────────────────────────────
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

        // ── Illustration (Custom Design from Image) ───────────
        Stack(
          alignment: Alignment.center,
          children: [
            // Background light gray circle
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: Color(0xFFEDF1F7),
                shape: BoxShape.circle,
              ),
            ),
            
            // The phone rectangle
            Container(
              width: 70,
              height: 110,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1644FF), width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            // Sparkling dots (dots from image)
            Positioned(
              top: 30, right: 20,
              child: Icon(Icons.circle, size: 4, color: Colors.green[400]),
            ),
            Positioned(
              bottom: 40, left: 20,
              child: Icon(Icons.circle, size: 4, color: Colors.red[400]),
            ),
            Positioned(
              top: 40, left: 20,
              child: Icon(Icons.circle, size: 4, color: Colors.orange[400]),
            ),

            // Checkmark Overlay
            Positioned(
              bottom: 30, right: -10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1644FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '****',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E283D),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 48),

        // ── Text Content ──────────────────────────────────────
        const Text(
          'Password updated!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E283D),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        const Text(
          'Your password has been setup successfully',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF8B92A5),
          ),
          textAlign: TextAlign.center,
        ),

        const Spacer(),

        // ── Back to Login Button ──────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1644FF).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1644FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'BACK TO LOGIN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}
