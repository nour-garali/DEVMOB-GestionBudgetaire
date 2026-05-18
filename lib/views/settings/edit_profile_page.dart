import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/AuthService.dart';
import '../../utils/image_helper.dart';
import '../../utils/photo_widget.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  DateTime? _selectedDate;
  String _selectedCountry = 'Morocco';
  bool _isLoading = false;
  bool _isPickingImage = false;
  String? _errorMessage;

  Uint8List? _imageBytes;
  bool _photoRemoved = false;

  static const List<String> _countries = [
    'Morocco', 'France', 'Algeria', 'Tunisia', 'Belgium',
    'Canada', 'Senegal', "Ivory Coast", 'Other',
  ];

  static const Map<String, String> _countryFlags = {
    'Morocco': '🇲🇦', 'France': '🇫🇷', 'Algeria': '🇩🇿', 'Tunisia': '🇹🇳',
    'Belgium': '🇧🇪', 'Canada': '🇨🇦', 'Senegal': '🇸🇳', "Ivory Coast": '🇨🇮',
    'Other': '🌍',
  };

  // Gradient colors (blue theme matching the app)
  static const _gradientStart = Color(0xFF1644FF); // Transaction main blue
  static const _gradientEnd = Color(0xFF3B82F6);   // Transaction secondary blue
  static const _accentBlue = Color(0xFF1644FF);

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _selectedCountry = user?.country ?? 'Morocco';
    _selectedDate = user?.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Photo picker ──────────────────────────────────────────────────────
  Future<void> _showPhotoPicker() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final hasPhoto = (_imageBytes != null) ||
        (!_photoRemoved && (user?.photoUrl?.isNotEmpty ?? false));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Profile Picture',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 24),
                _sheetOption(
                  icon: kIsWeb ? Icons.cloud_upload_outlined : Icons.photo_library_outlined,
                  label: kIsWeb ? 'Upload File' : 'Photo Gallery',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickImage(camera: false);
                  },
                ),
                if (!kIsWeb) ...[
                  const SizedBox(height: 12),
                  _sheetOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _pickImage(camera: true);
                    },
                  ),
                ],
                if (hasPhoto) ...[
                  const SizedBox(height: 12),
                  _sheetOption(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove Photo',
                    color: const Color(0xFFDC2626),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _imageBytes = null;
                        _photoRemoved = true;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage({required bool camera}) async {
    try {
      final bytes = await pickImageBytes(camera: camera);
      if (bytes != null && mounted) {
        setState(() {
          _imageBytes = bytes;
          _photoRemoved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error: $e');
      }
    }
  }

  // ── Upload photo ──────────────────────────────────────────────────────
  Future<String?> _uploadPhoto(String uid) async {
    if (_imageBytes == null) return null;

    if (kIsWeb) {
      final base64Str = base64Encode(_imageBytes!);
      return 'data:image/jpeg;base64,$base64Str';
    }

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child('$uid.jpg');

    try {
      final uploadTask = ref.putData(
        _imageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw TimeoutException("Upload timed out."),
      );
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Upload error: $e");
    }
  }

  // ── Date picker ──────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1644FF),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF0F172A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Save changes ──────────────────────────────────────────────────────
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.user?.uid;
      if (uid == null) throw Exception('Not connected');

      String? photoUrl;
      if (_imageBytes != null) {
        photoUrl = await _uploadPhoto(uid);
      } else if (_photoRemoved) {
        photoUrl = '';
      }

      final Map<String, dynamic> updates = {
        'name': _nameController.text.trim(),
        'country': _selectedCountry,
      };
      if (_selectedDate != null) {
        updates['dateOfBirth'] = Timestamp.fromDate(_selectedDate!);
      }
      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
      }

      await AuthService().updateProfile(uid, updates);
      await authProvider.refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Profile updated successfully!', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: _accentBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final String displayName = user?.name ?? 'User';
    final String displayEmail = user?.email ?? '';
    final String currentPhotoUrl = user?.photoUrl ?? '';
    final String initials = displayName.trim().split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .take(2)
        .join();

    Widget avatarContent;
    if (_imageBytes != null) {
      avatarContent = Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else if (!_photoRemoved && currentPhotoUrl.isNotEmpty) {
      avatarContent = ProfilePhoto(
        photoUrl: currentPhotoUrl,
        fallback: _initialsWidget(initials),
      );
    } else {
      avatarContent = _initialsWidget(initials);
    }

    final double headerHeight = 220;
    final double avatarSize = 120;
    final double avatarOverlap = avatarSize / 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ══════════════════════════════════════════════════════════
              // GRADIENT HEADER + AVATAR
              // ══════════════════════════════════════════════════════════
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Gradient background
                  Container(
                    height: headerHeight,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_gradientStart, _gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Back button row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Avatar (overlapping gradient + white card)
                  Positioned(
                    top: headerHeight - avatarOverlap - 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _isPickingImage ? null : _showPhotoPicker,
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                // Avatar circle
                                Container(
                                  width: avatarSize,
                                  height: avatarSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _gradientStart.withOpacity(0.25),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _isPickingImage
                                        ? Container(
                                            color: const Color(0xFFEFF6FF),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: _accentBlue,
                                                strokeWidth: 2.5,
                                              ),
                                            ),
                                          )
                                        : avatarContent,
                                  ),
                                ),
                                // Camera badge
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [_gradientStart, _gradientEnd],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _gradientStart.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Name + edit icon
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _accentBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Icon(Icons.edit_rounded, size: 13, color: _accentBlue),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Spacer for overlapping avatar + name
              SizedBox(height: avatarOverlap + 45),

              // ══════════════════════════════════════════════════════════
              // WHITE FORM CARD
              // ══════════════════════════════════════════════════════════
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    const SizedBox(height: 28),

                    // ── Nom ─────────────────────────────────────────────
                    _fieldLabel('User Name'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 18, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null,
                      decoration: _fieldDeco(
                        hint: 'Enter your name',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Email ───────────────────────────────────────────
                    _fieldLabel('Email Address'),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: displayEmail,
                      readOnly: true,
                      style: const TextStyle(fontSize: 18, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      decoration: _fieldDeco(
                        hint: 'E-mail',
                        icon: Icons.mail_outline_rounded,
                      ).copyWith(
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Date de naissance ───────────────────────────────
                    _fieldLabel('Date of Birth'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 6),
                            _iconCircle(Icons.calendar_month_rounded),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.day.toString().padLeft(2, '0')} / '
                                      '${_selectedDate!.month.toString().padLeft(2, '0')} / '
                                      '${_selectedDate!.year}'
                                    : 'DD / MM / YYYY',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedDate != null
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFB0B7C3),
                                ),
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400, size: 24),
                            const SizedBox(width: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Pays / Région ───────────────────────────────────
                    _fieldLabel('Country / Region'),
                    const SizedBox(height: 10),
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 6),
                          _iconCircle(Icons.public_rounded),
                          const SizedBox(width: 4),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCountry,
                                isExpanded: true,
                                icon: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400, size: 24),
                                ),
                                style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                items: _countries.map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Row(
                                    children: [
                                      Text(_countryFlags[c] ?? '🌍', style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 10),
                                      Text(c),
                                    ],
                                  ),
                                )).toList(),
                                selectedItemBuilder: (context) => _countries.map((c) => Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Row(
                                      children: [
                                        Text(_countryFlags[c] ?? '🌍', style: const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 10),
                                        Text(c, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                )).toList(),
                                onChanged: (v) { if (v != null) setState(() => _selectedCountry = v); },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Error message ───────────────────────────────────
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // ── SAVE Button ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_gradientStart, _gradientEnd],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: _gradientStart.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.transparent,
                            disabledForegroundColor: Colors.white70,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'SAVE',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════════════════

  Widget _initialsWidget(String initials) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStart, _gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 40,
              letterSpacing: 1,
            ),
          ),
        ),
      );

  Widget _iconCircle(IconData icon) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_accentBlue.withOpacity(0.15), _gradientEnd.withOpacity(0.15)],
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: _accentBlue),
      );

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8),
        ),
      );

  InputDecoration _fieldDeco({required String hint, required IconData icon}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.normal),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, right: 8),
          child: _iconCircle(icon),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 60, minHeight: 42),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: _accentBlue, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFDC2626))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
      );

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF1E293B),
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color == const Color(0xFFDC2626)
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF2F6)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color == const Color(0xFFDC2626)
                      ? const Color(0xFFFEE2E2)
                      : _accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color == const Color(0xFFDC2626) ? color : _accentBlue, size: 20),
              ),
              const SizedBox(width: 14),
              Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 22),
            ],
          ),
        ),
      );
}
