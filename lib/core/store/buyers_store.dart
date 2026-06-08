import 'package:flutter/foundation.dart';

import '../../features/buyers/models/buyer.dart';
import '../../features/buyers/repositories/buyer_repository.dart';
import 'store_state.dart';
import 'stream_store.dart';

class BuyersStore {
  BuyersStore._();

  static final _store =
      StreamStore<Buyer>(() => BuyerRepository().watchBuyers());

  static ValueNotifier<StoreState<List<Buyer>>> get state => _store.state;
  static List<Buyer>? get current => _store.current;
  static void init() => _store.init();
  static void ensureSubscribed() => _store.ensureSubscribed();
  static void forceReset() => _store.forceReset();
  static void dispose() => _store.dispose();
}
