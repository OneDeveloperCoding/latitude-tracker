import 'package:flutter/foundation.dart';
import 'package:latitude_tracker/core/store/store_state.dart';
import 'package:latitude_tracker/core/store/stream_store.dart';
import 'package:latitude_tracker/features/buyers/models/buyer.dart';
import 'package:latitude_tracker/features/buyers/repositories/buyer_repository.dart';

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
