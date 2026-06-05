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

  static List<Buyer>? get current =>
      state.value is StoreLoaded<List<Buyer>>
          ? (state.value as StoreLoaded<List<Buyer>>).data
          : null;

  static void init() {
    if (_sub != null) return;
    state.value = const StoreLoading();
    _sub = BuyerRepository().watchBuyers().listen(
      (buyers) => state.value = StoreLoaded(buyers),
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
