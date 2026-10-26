import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main_screen.dart';
import 'login_screen.dart';
import '../../theme/app_theme.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.black,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.blue),
            ),
          );
        }

        // Signed-in user
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }

        // Signed out: show the login page
        return const LoginScreen();
      },
    );
  }
}
