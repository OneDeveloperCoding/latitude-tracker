import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/l10n/locale_settings.dart';
import 'core/theme/theme_settings.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Catches async errors that bypass both FlutterError.onError and the zone —
    // e.g. uncaught exceptions in platform-channel callbacks (map library crashes).
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    await LocaleSettings.init();
    await ThemeSettings.init();

    runApp(const LatitudeTrackerApp());
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
}
