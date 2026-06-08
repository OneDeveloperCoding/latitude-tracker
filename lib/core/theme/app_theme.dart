import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFFB5714A);

  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  static final ThemeData dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}
