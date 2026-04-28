import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:email_validator/email_validator.dart';
import '../../l10n/app_strings.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1 - Hisob ma'lumotlari
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 2 - Profil ma'lumotlari
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isConfirmHidden = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = false;
  XFile? _profileImage;
  Uint8List? _profileImageBytes;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _authService = AuthService();

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 600,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _profileImage = picked;
        _profileImageBytes = bytes;
      });
    }
  }

  Future<void> _checkUsername(String username) async {
    if (username.length < 3) {
      setState(() => _isUsernameAvailable = false);
      return;
    }
    setState(() => _isCheckingUsername = true);
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();
    if (mounted) {
      setState(() {
        _isUsernameAvailable = snap.docs.isEmpty;
        _isCheckingUsername = false;
      });
    }
  }

  void _goToNextStep() {
    if (!_formKey1.currentState!.validate()) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = 1);
  }

  void _goToPrevStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = 0);
  }

  Future<void> _register() async {
    if (!_formKey2.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        profileImage: _profileImage,
      );
      if (!mounted) return;
      _showSuccess(context.tr('register_success_verify_email'));
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await _authService.signInWithGoogle();
      // AuthWrapper avtomatik asosiy ekranga yo'naltiradi
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        leading: IconButton(
          onPressed: _currentStep == 0
              ? () => Navigator.pop(context)
              : _goToPrevStep,
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white),
        ),
        title: ShaderMask(
          shaderCallback: (b) => AppTheme.logoGradient.createShader(b),
          child: const Text(
            'Instagram',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress bar
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildStep1(), _buildStep2()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 2,
                backgroundColor: AppTheme.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.blue),
                minHeight: 3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_currentStep + 1}/2',
            style: const TextStyle(color: AppTheme.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Email va parol ───────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('register_account_info_title'),
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('register_account_info_subtitle'),
              style: const TextStyle(color: AppTheme.grey, fontSize: 14),
            ),
            const SizedBox(height: 28),
            _buildLabel(context.tr('email_address')),
            const SizedBox(height: 8),
            _buildFormField(
              controller: _emailController,
              hint: context.tr('email_placeholder'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return context.tr('enter_email');
                if (!EmailValidator.validate(v)) {
                  return context.tr('invalid_email');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildLabel(context.tr('password')),
            const SizedBox(height: 8),
            _buildFormField(
              controller: _passwordController,
              hint: context.tr('password_hint_min6'),
              obscureText: _isPasswordHidden,
              validator: (v) {
                if (v == null || v.isEmpty) return context.tr('enter_password');
                if (v.length < 6) {
                  return context.tr('password_min_6');
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.grey,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _isPasswordHidden = !_isPasswordHidden),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel(context.tr('confirm_password_label')),
            const SizedBox(height: 8),
            _buildFormField(
              controller: _confirmPasswordController,
              hint: context.tr('reenter_password'),
              obscureText: _isConfirmHidden,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return context.tr('confirm_password_required');
                }
                if (v != _passwordController.text) {
                  return context.tr('passwords_not_match');
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.grey,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _isConfirmHidden = !_isConfirmHidden),
              ),
            ),
            const SizedBox(height: 32),
            _buildPrimaryButton(
              label: context.tr('continue_button'),
              isLoading: false,
              onTap: _goToNextStep,
            ),
            const SizedBox(height: 20),
            _buildDivider(context.tr('or')),
            const SizedBox(height: 16),
            _buildGoogleButton(
              isLoading: _isGoogleLoading,
              onTap: _signInWithGoogle,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 2: Profil ma'lumotlari ─────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('create_profile_title'),
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('register_profile_subtitle'),
              style: const TextStyle(color: AppTheme.grey, fontSize: 14),
            ),
            const SizedBox(height: 28),
            // Profil rasmi
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.darkGrey,
                        border: Border.all(color: AppTheme.divider, width: 2),
                        image: _profileImage != null
                            ? DecorationImage(
                                image: MemoryImage(_profileImageBytes!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profileImage == null
                          ? const Icon(
                              Icons.person,
                              color: AppTheme.grey,
                              size: 40,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppTheme.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                context.tr('add_profile_photo_optional'),
                style: const TextStyle(color: AppTheme.blue, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel(context.tr('username_label')),
            const SizedBox(height: 8),
            _buildFormField(
              controller: _usernameController,
              hint: context.tr('username_hint'),
              onChanged: _checkUsername,
              validator: (v) {
                if (v == null || v.isEmpty) return context.tr('enter_username');
                if (v.length < 3) return context.tr('min_3_chars');
                if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v)) {
                  return context.tr('username_allowed_chars');
                }
                return null;
              },
              suffixIcon: _isCheckingUsername
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.grey,
                        ),
                      ),
                    )
                  : _usernameController.text.length >= 3
                  ? Icon(
                      _isUsernameAvailable ? Icons.check_circle : Icons.cancel,
                      color: _isUsernameAvailable ? Colors.green : AppTheme.red,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            _buildLabel(context.tr('full_name_label')),
            const SizedBox(height: 8),
            _buildFormField(
              controller: _displayNameController,
              hint: context.tr('full_name_placeholder'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return context.tr('enter_name');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildLabel(context.tr('bio_optional_label')),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bioController,
              style: const TextStyle(color: AppTheme.white, fontSize: 14),
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: context.tr('bio_hint'),
                hintStyle: const TextStyle(color: AppTheme.grey, fontSize: 13),
                filled: true,
                fillColor: AppTheme.darkGrey,
                counterStyle: const TextStyle(color: AppTheme.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.grey),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            _buildPrimaryButton(
              label: context.tr('sign_up'),
              isLoading: _isLoading,
              onTap: _register,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.white, fontSize: 14),
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.grey, fontSize: 13),
        filled: true,
        fillColor: AppTheme.darkGrey,
        suffixIcon: suffixIcon,
        errorStyle: const TextStyle(color: AppTheme.red, fontSize: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.grey),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.blue,
          disabledBackgroundColor: AppTheme.blue.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.grey, fontSize: 13),
          ),
        ),
        const Expanded(child: Divider(color: AppTheme.divider)),
      ],
    );
  }

  Widget _buildGoogleButton({
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    width: 20,
                    height: 20,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.g_mobiledata,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.tr('register_with_google'),
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
