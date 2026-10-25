import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_widgets.dart';
import 'register_screen.dart';
import 'phone_auth_screen.dart';
import 'forgot_password_screen.dart';

const _wordmarkStyle = TextStyle(
  color: AppTheme.ink,
  fontSize: 40,
  fontWeight: FontWeight.w700,
  letterSpacing: -1.5,
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmail(
        emailOrUsername: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // AuthWrapper switches to the main screen once the auth state changes.
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      AppTheme.appName,
                      textAlign: TextAlign.center,
                      style: _wordmarkStyle,
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTheme.bodyStyle,
                      decoration: InputDecoration(
                        hintText: context.tr('login_email_or_username'),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return context.tr('fill_field');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isPasswordHidden,
                      style: AppTheme.bodyStyle,
                      decoration: InputDecoration(
                        hintText: context.tr('password'),
                        suffixIcon: VisibilityToggle(
                          isHidden: _isPasswordHidden,
                          onPressed: () => setState(
                            () => _isPasswordHidden = !_isPasswordHidden,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return context.tr('enter_password');
                        }
                        if (v.length < 6) return context.tr('password_min_6');
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: Text(context.tr('forgot_password')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: context.tr('login'),
                      isLoading: _isLoading,
                      onPressed: _login,
                    ),
                    const SizedBox(height: 24),
                    LabeledDivider(context.tr('or')),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PhoneAuthScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.phone_outlined, size: 20),
                      label: Text(context.tr('login_with_phone')),
                    ),
                    const SizedBox(height: 12),
                    GoogleButton(
                      label: context.tr('login_with_google'),
                      isLoading: _isGoogleLoading,
                      onPressed: _signInWithGoogle,
                    ),
                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${context.tr('no_account')} ',
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                          child: Text(
                            context.tr('sign_up'),
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }
}
