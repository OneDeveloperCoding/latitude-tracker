import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFFB5714A);

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }
}
