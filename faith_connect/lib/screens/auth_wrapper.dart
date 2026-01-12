import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'landing_screen.dart';
import 'main_wrapper.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in, go to MainWrapper
        if (snapshot.hasData && snapshot.data != null) {
          return const MainWrapper();
        }

        // If no user, show LandingScreen
        return const LandingScreen();
      },
    );
  }
}
