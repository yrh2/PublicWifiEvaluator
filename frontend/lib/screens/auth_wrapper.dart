import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        print('🔍 AuthWrapper - isSignedIn: ${authService.isSignedIn}');
        print(
          '🔍 AuthWrapper - currentUser: ${authService.currentUser?.email ?? 'null'}',
        );

        if (authService.isSignedIn) {
          print('✅ User is signed in - showing HomeScreen');
          return const HomeScreen();
        } else {
          print('❌ User is not signed in - showing LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }
}
