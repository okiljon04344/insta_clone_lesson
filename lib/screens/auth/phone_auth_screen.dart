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
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_widgets.dart';

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
      showAppSnackBar(context, context.tr('enter_phone_number'), isError: true);
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
        showAppSnackBar(context, context.tr('otp_sent'));
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        showAppSnackBar(context, error, isError: true);
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
      showAppSnackBar(context, e.message, isError: true);
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
      showAppSnackBar(context, context.tr('enter_6_digit_code'), isError: true);
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
      showAppSnackBar(context, e.message, isError: true);
    }
  }

  Future<void> _completeProfile() async {
    final fillAllFieldsText = context.tr('fill_all_fields');
    final usernameTakenText = context.tr('username_taken');
    final errorPrefixText = context.tr('error_prefix');

    if (_usernameController.text.trim().isEmpty ||
        _displayNameController.text.trim().isEmpty) {
      showAppSnackBar(context, fillAllFieldsText, isError: true);
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
      if (!mounted) return;
      if (usernameQuery.docs.isNotEmpty) {
        showAppSnackBar(context, usernameTakenText, isError: true);
        setState(() => _isLoading = false);
        return;
      }

      String photoUrl = '';
      final profileImage = _profileImage;
      if (profileImage != null) {
        photoUrl = await SupabaseStorageService().uploadAvatar(
          uid: user.uid,
          image: profileImage,
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
      if (mounted) {
        showAppSnackBar(context, '$errorPrefixText: $e', isError: true);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        title: const Text(AppTheme.appName, style: AppTheme.wordmarkStyle),
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
    return _Page(
      key: const ValueKey('phone'),
      children: [
        AuthHeader(
          title: context.tr('enter_phone_title'),
          subtitle: context.tr('enter_phone_subtitle'),
        ),
        const SizedBox(height: 32),
        IntlPhoneField(
          controller: _phoneController,
          initialCountryCode: 'UZ',
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTheme.bodyStyle,
          dropdownTextStyle: AppTheme.bodyStyle,
          decoration: InputDecoration(
            hintText: context.tr('phone_placeholder'),
            counterText: '',
          ),
          onChanged: (phone) => _fullPhoneNumber = phone.completeNumber,
          onCountryChanged: (_) => _fullPhoneNumber = '',
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('phone_supported_countries'),
          style: AppTheme.captionStyle,
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: context.tr('send_code'),
          isLoading: _isLoading,
          onPressed: _sendOtp,
        ),
      ],
    );
  }

  Widget _buildOtpView() {
    return _Page(
      key: const ValueKey('otp'),
      children: [
        AuthHeader(
          title: context.tr('enter_code_title'),
          subtitle: context
              .tr('code_sent_to')
              .replaceAll('{phone}', _fullPhoneNumber),
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
            color: AppTheme.ink,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 16,
          ),
          decoration: const InputDecoration(
            hintText: '------',
            hintStyle: TextStyle(
              color: AppTheme.muted,
              fontSize: 28,
              letterSpacing: 16,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 20),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: _resendTimer > 0
              ? Text(
                  '${context.tr('resend_in')}: ${_resendTimer}s',
                  style: AppTheme.captionStyle,
                )
              : TextButton(
                  onPressed: _sendOtp,
                  child: Text(context.tr('resend_code')),
                ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: context.tr('verify'),
          isLoading: _isLoading,
          onPressed: _verifyOtp,
        ),
      ],
    );
  }

  Widget _buildCompleteProfileView() {
    return _Page(
      key: const ValueKey('profile'),
      children: [
        AuthHeader(
          title: context.tr('create_profile_title'),
          subtitle: context.tr('create_profile_subtitle'),
        ),
        const SizedBox(height: 24),
        Center(
          child: AvatarPicker(
            imageBytes: _profileImageBytes,
            onTap: _pickImage,
          ),
        ),
        const SizedBox(height: 24),
        FieldLabel(context.tr('username_label')),
        TextField(
          controller: _usernameController,
          style: AppTheme.bodyStyle,
          decoration: InputDecoration(
            hintText: context.tr('username_placeholder'),
          ),
        ),
        const SizedBox(height: 16),
        FieldLabel(context.tr('full_name_label')),
        TextField(
          controller: _displayNameController,
          style: AppTheme.bodyStyle,
          decoration: InputDecoration(
            hintText: context.tr('full_name_placeholder'),
          ),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: context.tr('start'),
          isLoading: _isLoading,
          onPressed: _completeProfile,
        ),
      ],
    );
  }
}

/// Scrollable page body with a readable maximum width on large screens.
class _Page extends StatelessWidget {
  final List<Widget> children;

  const _Page({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
