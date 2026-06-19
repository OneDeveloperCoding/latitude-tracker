import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:latitude_tracker/core/l10n/locale_settings.dart';
import 'package:latitude_tracker/core/navigation/main_nav.dart';
import 'package:latitude_tracker/core/theme/app_theme.dart';
import 'package:latitude_tracker/core/theme/theme_settings.dart';
import 'package:latitude_tracker/features/auth/screens/login_screen.dart';
import 'package:latitude_tracker/features/demo/demo_mode.dart';

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
              themeMode: ThemeMode.light,
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
                  return StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return snapshot.hasData
                          ? const MainNav()
                          : const LoginScreen();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
