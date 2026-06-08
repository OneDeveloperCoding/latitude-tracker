import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/locale_settings.dart';
import 'core/navigation/main_nav.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_settings.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/demo/demo_mode.dart';

class LatitudeTrackerApp extends StatelessWidget {
  const LatitudeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeSettings.themeMode,
      builder: (context, themeMode, child) => ValueListenableBuilder<Locale>(
        valueListenable: LocaleSettings.locale,
        builder: (context, locale, _) => AppLocaleScope(
          locale: locale,
          child: MaterialApp(
            title: 'Latitude Tracker',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
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
    );
  }
}
