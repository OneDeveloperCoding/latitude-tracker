import 'package:flutter/foundation.dart';

import '../../features/buyers/models/buyer_address.dart';
import '../../features/buyers/repositories/buyer_repository.dart';
import 'store_state.dart';
import 'stream_store.dart';

class AddressesStore {
  AddressesStore._();

  static final _store =
      StreamStore<BuyerAddress>(() => BuyerRepository().watchAllAddresses());

  static ValueNotifier<StoreState<List<BuyerAddress>>> get state =>
      _store.state;
  static List<BuyerAddress>? get current => _store.current;
  static void init() => _store.init();
  static void ensureSubscribed() => _store.ensureSubscribed();
  static void forceReset() => _store.forceReset();
  static void dispose() => _store.dispose();
}
