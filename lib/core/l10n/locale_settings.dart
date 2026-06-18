import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleSettings {
  LocaleSettings._();

  static const _key = 'locale';
  static const defaultLocale = Locale('pt');

  static final locale = ValueNotifier<Locale>(defaultLocale);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'pt';
    locale.value = Locale(code);
    Intl.defaultLocale = _intlLocale(code);
  }

  static Future<void> setLocale(Locale l) async {
    locale.value = l;
    Intl.defaultLocale = _intlLocale(l.languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, l.languageCode);
  }

  static String _intlLocale(String code) => code == 'pt' ? 'pt_PT' : 'en_US';
}

/// Propagates the active [Locale] down the widget tree via InheritedWidget so
/// that any widget calling [AppLocaleScope.of] (or `context.s`) rebuilds
/// automatically when the locale changes — without needing explicit
/// ValueListenableBuilder wrappers at each call site.
class AppLocaleScope extends InheritedWidget {
  const AppLocaleScope({
    required this.locale,
    required super.child,
    super.key,
  });
  final Locale locale;

  static Locale of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLocaleScope>()?.locale ??
      LocaleSettings.defaultLocale;

  @override
  bool updateShouldNotify(AppLocaleScope old) => locale != old.locale;
}
