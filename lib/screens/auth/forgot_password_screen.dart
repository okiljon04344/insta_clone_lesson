import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import '../../l10n/app_strings.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAppSnackBar(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        title: const Text(AppTheme.appName, style: AppTheme.wordmarkStyle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _emailSent ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.lock_outline, size: 48),
          const SizedBox(height: 24),
          AuthHeader(
            title: context.tr('forgot_password_title'),
            subtitle: context.tr('forgot_password_desc'),
            alignment: CrossAxisAlignment.center,
          ),
          const SizedBox(height: 32),
          FieldLabel(context.tr('email_address')),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: AppTheme.bodyStyle,
            validator: (v) {
              if (v == null || v.isEmpty) return context.tr('enter_email');
              if (!EmailValidator.validate(v)) {
                return context.tr('invalid_email');
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: context.tr('email_placeholder'),
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppTheme.muted,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: context.tr('send_reset_link'),
            isLoading: _isLoading,
            onPressed: _sendResetEmail,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('back_to_login'),
              style: const TextStyle(color: AppTheme.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const Icon(
          Icons.mark_email_read_outlined,
          color: AppTheme.accent,
          size: 48,
        ),
        const SizedBox(height: 24),
        AuthHeader(
          title: context.tr('email_sent_title'),
          subtitle: context
              .tr('email_sent_desc')
              .replaceAll('{email}', _emailController.text),
          alignment: CrossAxisAlignment.center,
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('check_spam'),
          textAlign: TextAlign.center,
          style: AppTheme.captionStyle,
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: context.tr('back_to_login'),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _emailSent = false),
          child: Text(
            context.tr('resend'),
            style: const TextStyle(color: AppTheme.muted),
          ),
        ),
      ],
    );
  }
}
