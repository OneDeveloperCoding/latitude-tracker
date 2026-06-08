import 'package:flutter/material.dart';

// M3 has no standard tokens for success/warning/shipped/pending.
// These extension getters pick the right shade for each brightness so
// status icons stay legible in both light and dark themes.
extension AppColorScheme on ColorScheme {
  Color get success =>
      brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade600;

  Color get warning =>
      brightness == Brightness.dark ? Colors.orange.shade300 : Colors.orange.shade700;

  Color get muted => outline;

  Color get shipped =>
      brightness == Brightness.dark ? Colors.blue.shade200 : Colors.blue.shade700;

  Color get pending =>
      brightness == Brightness.dark ? Colors.purple.shade200 : Colors.purple.shade700;
}
