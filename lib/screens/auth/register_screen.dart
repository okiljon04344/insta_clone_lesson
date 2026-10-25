import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:email_validator/email_validator.dart';
import '../../l10n/app_strings.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1: account details
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 2: profile details
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
      showAppSnackBar(context, context.tr('register_success_verify_email'));
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await _authService.signInWithGoogle();
    } on AuthException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _currentStep == 0
              ? () => Navigator.pop(context)
              : _goToPrevStep,
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        title: const Text(AppTheme.appName, style: AppTheme.wordmarkStyle),
        centerTitle: true,
      ),
      body: Column(
        children: [
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 464),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 2,
                    backgroundColor: AppTheme.border,
                    minHeight: 3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${_currentStep + 1}/2', style: AppTheme.captionStyle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return _FormPage(
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: context.tr('register_account_info_title'),
              subtitle: context.tr('register_account_info_subtitle'),
            ),
            const SizedBox(height: 24),
            FieldLabel(context.tr('email_address')),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppTheme.bodyStyle,
              decoration: InputDecoration(
                hintText: context.tr('email_placeholder'),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return context.tr('enter_email');
                if (!EmailValidator.validate(v)) {
                  return context.tr('invalid_email');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FieldLabel(context.tr('password')),
            TextFormField(
              controller: _passwordController,
              obscureText: _isPasswordHidden,
              style: AppTheme.bodyStyle,
              decoration: InputDecoration(
                hintText: context.tr('password_hint_min6'),
                suffixIcon: VisibilityToggle(
                  isHidden: _isPasswordHidden,
                  onPressed: () =>
                      setState(() => _isPasswordHidden = !_isPasswordHidden),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return context.tr('enter_password');
                if (v.length < 6) return context.tr('password_min_6');
                return null;
              },
            ),
            const SizedBox(height: 16),
            FieldLabel(context.tr('confirm_password_label')),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _isConfirmHidden,
              style: AppTheme.bodyStyle,
              decoration: InputDecoration(
                hintText: context.tr('reenter_password'),
                suffixIcon: VisibilityToggle(
                  isHidden: _isConfirmHidden,
                  onPressed: () =>
                      setState(() => _isConfirmHidden = !_isConfirmHidden),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return context.tr('confirm_password_required');
                }
                if (v != _passwordController.text) {
                  return context.tr('passwords_not_match');
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: context.tr('continue_button'),
              onPressed: _goToNextStep,
            ),
            const SizedBox(height: 24),
            LabeledDivider(context.tr('or')),
            const SizedBox(height: 16),
            GoogleButton(
              label: context.tr('register_with_google'),
              isLoading: _isGoogleLoading,
              onPressed: _signInWithGoogle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameSuffix() {
    if (_isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.muted,
          ),
        ),
      );
    }
    if (_usernameController.text.length < 3) return const SizedBox.shrink();
    return Icon(
      _isUsernameAvailable ? Icons.check_circle_outline : Icons.cancel_outlined,
      color: _isUsernameAvailable ? AppTheme.accent : AppTheme.danger,
      size: 20,
    );
  }

  Widget _buildStep2() {
    return _FormPage(
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: context.tr('create_profile_title'),
              subtitle: context.tr('register_profile_subtitle'),
            ),
            const SizedBox(height: 24),
            Center(
              child: AvatarPicker(
                imageBytes: _profileImageBytes,
                onTap: _pickImage,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                context.tr('add_profile_photo_optional'),
                style: AppTheme.captionStyle,
              ),
            ),
            const SizedBox(height: 24),
            FieldLabel(context.tr('username_label')),
            TextFormField(
              controller: _usernameController,
              style: AppTheme.bodyStyle,
              onChanged: _checkUsername,
              decoration: InputDecoration(
                hintText: context.tr('username_hint'),
                suffixIcon: _buildUsernameSuffix(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return context.tr('enter_username');
                if (v.length < 3) return context.tr('min_3_chars');
                if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v)) {
                  return context.tr('username_allowed_chars');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FieldLabel(context.tr('full_name_label')),
            TextFormField(
              controller: _displayNameController,
              style: AppTheme.bodyStyle,
              decoration: InputDecoration(
                hintText: context.tr('full_name_placeholder'),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return context.tr('enter_name');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FieldLabel(context.tr('bio_optional_label')),
            TextFormField(
              controller: _bioController,
              style: AppTheme.bodyStyle,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(hintText: context.tr('bio_hint')),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: context.tr('sign_up'),
              isLoading: _isLoading,
              onPressed: _register,
            ),
          ],
        ),
      ),
    );
  }
}

/// Scrollable page body with a readable maximum width on large screens.
class _FormPage extends StatelessWidget {
  final Widget child;

  const _FormPage({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: child,
        ),
      ),
    );
  }
}
