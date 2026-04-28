import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../l10n/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_storage_service.dart';
import '../../theme/app_theme.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();

  final _authService = AuthService();
  String _fullPhoneNumber = '';
  String _verificationId = '';
  bool _isLoading = false;
  bool _otpSent = false;
  bool _isNewUser = false;
  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  int _resendTimer = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_fullPhoneNumber.isEmpty || _phoneController.text.trim().isEmpty) {
      _showError(context.tr('enter_phone_number'));
      return;
    }

    setState(() => _isLoading = true);
    await _authService.sendOtp(
      phoneNumber: _fullPhoneNumber,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _isLoading = false;
          _resendTimer = 60;
        });
        _startResendTimer();
        _showSuccess(context.tr('otp_sent'));
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError(error);
      },
      onAutoVerified: _handleAutoVerified,
    );
  }

  Future<void> _handleAutoVerified(UserCredential cred) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = await _authService.ensurePhoneUserProfile(cred);
      if (!mounted) return;
      if (user.username.startsWith('user_')) {
        setState(() {
          _isLoading = false;
          _isNewUser = true;
        });
      } else {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.message);
    }
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _resendTimer <= 0) return false;
      setState(() => _resendTimer--);
      return _resendTimer > 0;
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      _showError(context.tr('enter_6_digit_code'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.verifyOtpAndSignIn(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      if (!mounted) return;

      if (user.username.startsWith('user_')) {
        setState(() {
          _isLoading = false;
          _isNewUser = true;
        });
      } else {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.message);
    }
  }

  Future<void> _completeProfile() async {
    final fillAllFieldsText = context.tr('fill_all_fields');
    final usernameTakenText = context.tr('username_taken');
    final errorPrefixText = context.tr('error_prefix');

    if (_usernameController.text.trim().isEmpty ||
        _displayNameController.text.trim().isEmpty) {
      _showError(fillAllFieldsText);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final db = FirebaseFirestore.instance;
      final username = _usernameController.text.trim().toLowerCase();
      final displayName = _displayNameController.text.trim();

      final usernameQuery = await db
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (usernameQuery.docs.isNotEmpty) {
        _showError(usernameTakenText);
        setState(() => _isLoading = false);
        return;
      }

      String photoUrl = '';
      if (_profileImage != null) {
        photoUrl = await SupabaseStorageService().uploadAvatar(
          uid: user.uid,
          image: _profileImage!,
        );
        await user.updatePhotoURL(photoUrl);
      }

      await user.updateDisplayName(displayName);
      await db.collection('users').doc(user.uid).update({
        'username': username,
        'displayName': displayName,
        'photoUrl': photoUrl,
      });

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _showError('$errorPrefixText: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 600,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) {
      setState(() {
        _profileImage = picked;
        _profileImageBytes = bytes;
      });
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
          onPressed: () {
            if (_isNewUser) {
              setState(() => _isNewUser = false);
            } else if (_otpSent) {
              setState(() => _otpSent = false);
            } else {
              Navigator.pop(context);
            }
          },
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isNewUser
            ? _buildCompleteProfileView()
            : _otpSent
            ? _buildOtpView()
            : _buildPhoneView(),
      ),
    );
  }

  Widget _buildPhoneView() {
    return SingleChildScrollView(
      key: const ValueKey('phone'),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('enter_phone_title'),
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('enter_phone_subtitle'),
            style: const TextStyle(color: AppTheme.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          IntlPhoneField(
            controller: _phoneController,
            initialCountryCode: 'UZ',
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: AppTheme.white, fontSize: 14),
            dropdownTextStyle: const TextStyle(
              color: AppTheme.white,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: context.tr('phone_placeholder'),
              hintStyle: const TextStyle(color: AppTheme.grey, fontSize: 13),
              filled: true,
              fillColor: AppTheme.darkGrey,
              counterText: '',
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
            ),
            onChanged: (phone) => _fullPhoneNumber = phone.completeNumber,
            onCountryChanged: (_) => _fullPhoneNumber = '',
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('phone_supported_countries'),
            style: const TextStyle(color: AppTheme.grey, fontSize: 12),
          ),
          const SizedBox(height: 32),
          _buildPrimaryButton(
            label: context.tr('send_code'),
            isLoading: _isLoading,
            onTap: _sendOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpView() {
    return SingleChildScrollView(
      key: const ValueKey('otp'),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('enter_code_title'),
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('code_sent_to').replaceAll('{phone}', _fullPhoneNumber),
            style: const TextStyle(color: AppTheme.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 16,
            ),
            decoration: InputDecoration(
              hintText: '------',
              hintStyle: const TextStyle(
                color: AppTheme.grey,
                fontSize: 28,
                letterSpacing: 16,
              ),
              filled: true,
              fillColor: AppTheme.darkGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.blue),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: _resendTimer > 0
                ? Text(
                    '${context.tr('resend_in')}: ${_resendTimer}s',
                    style: const TextStyle(color: AppTheme.grey, fontSize: 13),
                  )
                : TextButton(
                    onPressed: _sendOtp,
                    child: Text(
                      context.tr('resend_code'),
                      style: const TextStyle(
                        color: AppTheme.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            label: context.tr('verify'),
            isLoading: _isLoading,
            onTap: _verifyOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteProfileView() {
    return SingleChildScrollView(
      key: const ValueKey('profile'),
      padding: const EdgeInsets.all(32),
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
            context.tr('create_profile_subtitle'),
            style: const TextStyle(color: AppTheme.grey, fontSize: 14),
          ),
          const SizedBox(height: 28),
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
                      image: _profileImageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_profileImageBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profileImageBytes == null
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
          const SizedBox(height: 24),
          Text(
            context.tr('username_label'),
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildSimpleField(
            _usernameController,
            context.tr('username_placeholder'),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('full_name_label'),
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildSimpleField(
            _displayNameController,
            context.tr('full_name_placeholder'),
          ),
          const SizedBox(height: 32),
          _buildPrimaryButton(
            label: context.tr('start'),
            isLoading: _isLoading,
            onTap: _completeProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppTheme.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.grey, fontSize: 13),
        filled: true,
        fillColor: AppTheme.darkGrey,
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
}
