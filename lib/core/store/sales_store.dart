import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_revoked_exception.dart';
import '../services/error_reporter.dart';
import 'package:flutter/foundation.dart';

import '../../features/sales/models/sale.dart';
import '../../features/sales/repositories/sale_repository.dart';
import 'store_state.dart';

class SalesStore {
  SalesStore._();

  static final state =
      ValueNotifier<StoreState<List<Sale>>>(const StoreLoading());
  static StreamSubscription<List<Sale>>? _sub;
  static int _refCount = 0;

  static List<Sale>? get current =>
      state.value is StoreLoaded<List<Sale>>
          ? (state.value as StoreLoaded<List<Sale>>).data
          : null;

  static void _tearDown() {
    _sub?.cancel();
    _sub = null;
  }

  static void _subscribe() {
    state.value = const StoreLoading();
    _sub = SaleRepository().watchSales().listen(
      (sales) => state.value = StoreLoaded(sales),
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

  // Called by MainNav.initState — increments the mount count so that a
  // dispose() from a stale widget instance cannot tear down an active store.
  static void init() {
    _refCount++;
    if (_sub == null) _subscribe();
  }

  // Called by MainNav.didChangeAppLifecycleState — re-subscribes when the
  // subscription is absent without affecting the mount count.
  static void ensureSubscribed() {
    if (_sub == null) _subscribe();
  }

  // Called by DemoMode before toggling active.value so the new MainNav's
  // init() finds _sub == null and opens a fresh subscription to the correct
  // (now-flipped) repository. Bypasses _refCount because the widget tree is
  // about to be fully replaced.
  static void forceReset() {
    _tearDown();
    _refCount = 0;
    state.value = const StoreLoading();
  }

  // Called by MainNav.dispose — only tears down when the last mounted
  // instance releases ownership.
  static void dispose() {
    if (_refCount > 0) _refCount--;
    if (_refCount > 0) return;
    _tearDown();
    state.value = const StoreLoading();
  }
}
