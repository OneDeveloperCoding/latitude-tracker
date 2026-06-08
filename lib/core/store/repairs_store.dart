import 'package:flutter/foundation.dart';

import '../../features/repairs/models/repair.dart';
import '../../features/repairs/repositories/repair_repository.dart';
import 'store_state.dart';
import 'stream_store.dart';

class RepairsStore {
  RepairsStore._();

  static final _store =
      StreamStore<Repair>(() => RepairRepository().watchRepairs());

  static ValueNotifier<StoreState<List<Repair>>> get state => _store.state;
  static List<Repair>? get current => _store.current;
  static void init() => _store.init();
  static void ensureSubscribed() => _store.ensureSubscribed();
  static void forceReset() => _store.forceReset();
  static void dispose() => _store.dispose();
}
