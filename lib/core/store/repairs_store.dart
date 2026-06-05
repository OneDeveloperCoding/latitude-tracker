import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_revoked_exception.dart';
import '../services/error_reporter.dart';
import 'package:flutter/foundation.dart';

import '../../features/repairs/models/repair.dart';
import '../../features/repairs/repositories/repair_repository.dart';
import 'store_state.dart';

class RepairsStore {
  RepairsStore._();

  static final state =
      ValueNotifier<StoreState<List<Repair>>>(const StoreLoading());
  static StreamSubscription<List<Repair>>? _sub;
  static int _refCount = 0;

  static List<Repair>? get current =>
      state.value is StoreLoaded<List<Repair>>
          ? (state.value as StoreLoaded<List<Repair>>).data
          : null;

  static void _tearDown() {
    _sub?.cancel();
    _sub = null;
  }

  static void _subscribe() {
    state.value = const StoreLoading();
    _sub = RepairRepository().watchRepairs().listen(
      (repairs) => state.value = StoreLoaded(repairs),
      onError: (e, StackTrace st) {
        _tearDown();
        if (e is AuthRevokedException ||
            (e is FirebaseException && e.code == 'permission-denied')) {
          state.value = const StoreLoading();
          FirebaseAuth.instance.signOut();
          return;
        }
        logError(e, st);
        state.value = StoreError(e);
      },
    );
  }

  static void init() {
    _refCount++;
    if (_sub == null) _subscribe();
  }

  static void ensureSubscribed() {
    if (_sub == null) _subscribe();
  }

  static void forceReset() {
    _tearDown();
    _refCount = 0;
    state.value = const StoreLoading();
  }

  static void dispose() {
    if (_refCount > 0) _refCount--;
    if (_refCount > 0) return;
    _tearDown();
    state.value = const StoreLoading();
  }
}
