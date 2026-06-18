import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:latitude_tracker/core/services/auth_revoked_exception.dart';
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/core/store/store_state.dart';

class StreamStore<T> {
  StreamStore(this._streamFactory);

  final Stream<List<T>> Function() _streamFactory;
  final state = ValueNotifier<StoreState<List<T>>>(const StoreLoading());
  StreamSubscription<List<T>>? _sub;
  int _refCount = 0;

  List<T>? get current => switch (state.value) {
    StoreLoaded(:final data) => data,
    _ => null,
  };

  List<T> get currentOrEmpty => current ?? [];

  void _tearDown() {
    if (_sub != null) unawaited(_sub!.cancel());
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
          _reset();
          unawaited(FirebaseAuth.instance.signOut());
          return;
        }
        logError(e, st);
        state.value = StoreError(e);
      },
    );
  }

  void init() {
    _refCount++;
    if (_sub == null) _subscribe();
  }

  void ensureSubscribed() {
    if (_sub == null) _subscribe();
  }

  // Bypasses _refCount — used before a DemoMode toggle so the new widget tree
  // opens a fresh subscription to the correct (now-flipped) repository.
  void forceReset() {
    _tearDown();
    _refCount = 0;
    _reset();
  }

  void dispose() {
    if (_refCount > 0) _refCount--;
    if (_refCount > 0) return;
    _tearDown();
    _reset();
  }

  void _reset() {
    state.value = const StoreLoading();
  }
}
