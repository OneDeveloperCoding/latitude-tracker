import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:latitude_tracker/core/l10n/locale_settings.dart';
import 'package:latitude_tracker/core/navigation/main_nav.dart';
import 'package:latitude_tracker/core/theme/app_theme.dart';
import 'package:latitude_tracker/core/theme/theme_settings.dart';
import 'package:latitude_tracker/features/auth/screens/login_screen.dart';
import 'package:latitude_tracker/features/demo/demo_mode.dart';

// Keeps the auth stream as a stable field so StreamBuilder never receives a
// new stream reference on parent rebuilds (which happen every animation frame
// during route transitions), preventing _MainNavState from being recreated.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final Stream<User?> _stream = FirebaseAuth.instance.authStateChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.hasData ? const MainNav() : const LoginScreen();
      },
    );
  }
}

class LatitudeTrackerApp extends StatelessWidget {
  const LatitudeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemePreset>(
      valueListenable: ThemeSettings.preset,
      builder: (context, activePreset, _) =>
          ValueListenableBuilder<Brightness>(
        valueListenable: ThemeSettings.brightness,
        builder: (context, activeBrightness, _) =>
            ValueListenableBuilder<Locale>(
          valueListenable: LocaleSettings.locale,
          builder: (context, locale, _) => AppLocaleScope(
            locale: locale,
            child: MaterialApp(
              title: 'Latitude Tracker',
              theme: AppTheme.forPreset(activePreset, activeBrightness),
              locale: locale,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('pt'), Locale('en')],
              home: ValueListenableBuilder<bool>(
                valueListenable: DemoMode.active,
                builder: (context, demoActive, _) {
                  if (demoActive) return const MainNav();
                  return const _AuthGate();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
