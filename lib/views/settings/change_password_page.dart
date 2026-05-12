import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  bool _success = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Non connecté');

      // Re-authenticate first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _oldPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text);

      setState(() { _isLoading = false; _success = true; });
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'wrong-password': msg = 'Ancien mot de passe incorrect.'; break;
        case 'weak-password': msg = 'Le mot de passe est trop faible.'; break;
        case 'requires-recent-login': msg = 'Veuillez vous reconnecter.'; break;
        default: msg = 'Erreur : ${e.message}';
      }
      setState(() { _isLoading = false; _errorMessage = msg; });
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Change Password",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        ),
      ),
      body: _success ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _label('Current Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _oldPasswordController,
              obscureText: _obscureOld,
              style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
              validator: (v) => (v == null || v.isEmpty) ? 'Field required' : null,
              decoration: _inputDecoration('••••••••', Icons.lock_outline_rounded).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8), size: 20),
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _label('New Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
              validator: (v) {
                if (v == null || v.length < 6) return 'Minimum 6 characters';
                return null;
              },
              decoration: _inputDecoration('••••••••', Icons.vpn_key_outlined).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8), size: 20),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _label('Confirm New Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
              validator: (v) {
                if (v != _newPasswordController.text) return 'Passwords do not match';
                return null;
              },
              decoration: _inputDecoration('••••••••', Icons.check_circle_outline_rounded).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8), size: 20),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1644FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Change Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // --- Illustration (Mocking the style from image) ---
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
              ),
              // Phone/Shield shape
              Container(
                width: 70,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1644FF), width: 4),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Floating Check/Badge
              Positioned(
                right: 20,
                bottom: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      )
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
                        child: const Icon(Icons.check, color: Colors.white, size: 10),
                      ),
                      const SizedBox(width: 6),
                      const Text('****', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),
              // Decorative dots
              const Positioned(left: 20, top: 40, child: CircleAvatar(radius: 3, backgroundColor: Color(0xFFF59E0B))),
              const Positioned(right: 30, top: 30, child: CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981))),
              const Positioned(left: 10, bottom: 50, child: CircleAvatar(radius: 3, backgroundColor: Color(0xFFEF4444))),
            ],
          ),
          
          const SizedBox(height: 60),
          
          const Text(
            'Password updated!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your password has been setup\nsuccessfully',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF94A3B8),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const Spacer(flex: 3),
          
          // --- Solid Blue Button ---
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1644FF),
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: const Color(0xFF1644FF).withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'BACK TO SETTINGS',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)));

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFB0B7C3), fontSize: 14),
    prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1644FF), width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626))),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
  );
}
