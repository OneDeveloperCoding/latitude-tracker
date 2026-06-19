import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettings {
  ThemeSettings._();

  static const _presetKey = 'theme_preset';
  static const _brightnessKey = 'theme_brightness';

  static final preset = ValueNotifier<ThemePreset>(ThemePreset.terracotta);
  static final brightness = ValueNotifier<Brightness>(Brightness.light);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    preset.value = _presetFromString(prefs.getString(_presetKey));
    brightness.value = _brightnessFromString(prefs.getString(_brightnessKey));
  }

  static Future<void> setPreset(ThemePreset value) async {
    preset.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_presetKey, value.name);
  }

  static Future<void> setBrightness(Brightness value) async {
    brightness.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_brightnessKey, _brightnessToString(value));
  }

  static ThemePreset _presetFromString(String? value) {
    if (value == null) return ThemePreset.terracotta;
    return ThemePreset.values.firstWhere(
      (p) => p.name == value,
      orElse: () => ThemePreset.terracotta,
    );
  }

  static Brightness _brightnessFromString(String? value) => switch (value) {
    'dark' => Brightness.dark,
    _ => Brightness.light,
  };

  static String _brightnessToString(Brightness value) =>
      value == Brightness.dark ? 'dark' : 'light';
}
