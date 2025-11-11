import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../profile/screens/profile_screen.dart';
import '../screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While waiting for Firebase to initialize
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (Firebase.apps.isEmpty) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        }

        // If user logged in
        if (snapshot.hasData) {
          return const ProfileScreen();
        }

        // If not logged in
        return const LoginScreen();
      },
    );
  }
}
