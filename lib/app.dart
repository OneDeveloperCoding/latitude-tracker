import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/navigation/main_nav.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/demo/demo_mode.dart';

class LatitudeTrackerApp extends StatelessWidget {
  const LatitudeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Latitude Tracker',
      theme: AppTheme.light(),
      home: ValueListenableBuilder<bool>(
        valueListenable: DemoMode.active,
        builder: (context, demoActive, _) {
          if (demoActive) return const MainNav();
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return snapshot.hasData ? const MainNav() : const LoginScreen();
            },
          );
        },
      ),
    );
  }
}
