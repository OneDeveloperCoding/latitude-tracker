import 'package:flutter/material.dart';

enum ThemePreset {
  terracotta(0xFFB5714A),
  ocean(0xFF2E86AB),
  forest(0xFF4A7C59),
  slate(0xFF546E7A),
  fuchsia(0xFFD81B60),
  indigo(0xFF3949AB);

  const ThemePreset(this.seedValue);

  final int seedValue;

  Color get seed => Color(seedValue);
}

class AppTheme {
  // 12 possible combinations (6 presets × 2 brightnesses) — cache them all.
  static final Map<(ThemePreset, Brightness), ThemeData> _cache = {};

  static ThemeData forPreset(ThemePreset preset, Brightness brightness) =>
      _cache.putIfAbsent(
        (preset, brightness),
        () => ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: preset.seed,
            brightness: brightness,
          ),
          useMaterial3: true,
        ),
      );

  static ColorScheme colorSchemeForPreset(
    ThemePreset preset,
    Brightness brightness,
  ) =>
      forPreset(preset, brightness).colorScheme;
}
