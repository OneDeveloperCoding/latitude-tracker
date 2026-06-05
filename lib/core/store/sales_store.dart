import 'dart:async';

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

  static List<Sale>? get current =>
      state.value is StoreLoaded<List<Sale>>
          ? (state.value as StoreLoaded<List<Sale>>).data
          : null;

  static void init() {
    if (_sub != null) return;
    state.value = const StoreLoading();
    _sub = SaleRepository().watchSales().listen(
      (sales) => state.value = StoreLoaded(sales),
      onError: (e, StackTrace st) {
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
