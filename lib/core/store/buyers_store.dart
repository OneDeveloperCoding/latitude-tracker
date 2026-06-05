import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_revoked_exception.dart';
import '../services/error_reporter.dart';
import 'package:flutter/foundation.dart';

import '../../features/buyers/models/buyer.dart';
import '../../features/buyers/repositories/buyer_repository.dart';
import 'store_state.dart';

class BuyersStore {
  BuyersStore._();

  static final state =
      ValueNotifier<StoreState<List<Buyer>>>(const StoreLoading());
  static StreamSubscription<List<Buyer>>? _sub;
  static int _refCount = 0;

  static List<Buyer>? get current =>
      state.value is StoreLoaded<List<Buyer>>
          ? (state.value as StoreLoaded<List<Buyer>>).data
          : null;

  static void _tearDown() {
    _sub?.cancel();
    _sub = null;
  }

  static void _subscribe() {
    state.value = const StoreLoading();
    _sub = BuyerRepository().watchBuyers().listen(
      (buyers) => state.value = StoreLoaded(buyers),
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

  static void dispose() {
    if (_refCount > 0) _refCount--;
    if (_refCount > 0) return;
    _tearDown();
    state.value = const StoreLoading();
  }
}
