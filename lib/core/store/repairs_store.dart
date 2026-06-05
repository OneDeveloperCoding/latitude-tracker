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

  static List<Repair>? get current =>
      state.value is StoreLoaded<List<Repair>>
          ? (state.value as StoreLoaded<List<Repair>>).data
          : null;

  static void init() {
    if (_sub != null) return;
    state.value = const StoreLoading();
    _sub = RepairRepository().watchRepairs().listen(
      (repairs) => state.value = StoreLoaded(repairs),
      onError: (e, StackTrace st) {
        if (e is AuthRevokedException ||
            (e is FirebaseException && e.code == 'permission-denied')) {
          _sub?.cancel();
          _sub = null;
          FirebaseAuth.instance.signOut();
          return;
        }
        logError(e, st);
        state.value = StoreError(e);
      },
    );
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
    state.value = const StoreLoading();
  }
}
