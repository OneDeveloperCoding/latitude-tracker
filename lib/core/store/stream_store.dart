import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_revoked_exception.dart';
import '../services/error_reporter.dart';
import 'store_state.dart';

class StreamStore<T> {
  StreamStore(this._streamFactory);

  final Stream<List<T>> Function() _streamFactory;
  final state = ValueNotifier<StoreState<List<T>>>(const StoreLoading());
  StreamSubscription<List<T>>? _sub;
  int _refCount = 0;

  List<T>? get current =>
      state.value is StoreLoaded<List<T>>
          ? (state.value as StoreLoaded<List<T>>).data
          : null;

  void _tearDown() {
    _sub?.cancel();
    _sub = null;
  }

  void _subscribe() {
    state.value = const StoreLoading();
    _sub = _streamFactory().listen(
      (items) => state.value = StoreLoaded(items),
      onError: (Object e, StackTrace st) {
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

  // Increments mount count; opens a subscription on first mount.
  void init() {
    _refCount++;
    if (_sub == null) _subscribe();
  }

  // Re-subscribes when the subscription is absent without affecting mount count.
  void ensureSubscribed() {
    if (_sub == null) _subscribe();
  }

  // Tears down the subscription and resets state without regard to mount count.
  // Used before a DemoMode toggle so the new widget tree opens a fresh
  // subscription to the correct (now-flipped) repository.
  void forceReset() {
    _tearDown();
    _refCount = 0;
    state.value = const StoreLoading();
  }

  // Decrements mount count; tears down only when the last owner releases.
  void dispose() {
    if (_refCount > 0) _refCount--;
    if (_refCount > 0) return;
    _tearDown();
    state.value = const StoreLoading();
  }
}
