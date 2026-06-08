import 'package:flutter/foundation.dart';

import '../../features/sales/models/sale.dart';
import '../../features/sales/repositories/sale_repository.dart';
import 'store_state.dart';
import 'stream_store.dart';

class SalesStore {
  SalesStore._();

  static final _store = StreamStore<Sale>(() => SaleRepository().watchSales());

  static ValueNotifier<StoreState<List<Sale>>> get state => _store.state;
  static List<Sale>? get current => _store.current;
  static void init() => _store.init();
  static void ensureSubscribed() => _store.ensureSubscribed();
  static void forceReset() => _store.forceReset();
  static void dispose() => _store.dispose();
}
