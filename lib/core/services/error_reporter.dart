import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void logError(Object e, StackTrace st) =>
    FirebaseCrashlytics.instance.recordError(e, st);
