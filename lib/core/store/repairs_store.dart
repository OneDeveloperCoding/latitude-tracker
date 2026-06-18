import 'package:flutter/foundation.dart';
import 'package:latitude_tracker/core/store/store_state.dart';
import 'package:latitude_tracker/core/store/stream_store.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/repairs/repositories/repair_repository.dart';

class RepairsStore {
  RepairsStore._();

  static final _store =
      StreamStore<Repair>(() => RepairRepository().watchRepairs());

  static ValueNotifier<StoreState<List<Repair>>> get state => _store.state;
  static List<Repair>? get current => _store.current;
  static List<Repair> get currentOrEmpty => _store.currentOrEmpty;
  static void init() => _store.init();
  static void ensureSubscribed() => _store.ensureSubscribed();
  static void forceReset() => _store.forceReset();
  static void dispose() => _store.dispose();
}
