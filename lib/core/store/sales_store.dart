import 'package:flutter/foundation.dart';
import 'package:latitude_tracker/core/store/store_state.dart';
import 'package:latitude_tracker/core/store/stream_store.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/repositories/sale_repository.dart';

class SalesStore {
  SalesStore._();

  static final _store = StreamStore<Sale>(() => SaleRepository().watchSales());

  /// Non-null while an undo window is open for a pending deletion.
  /// The sale with this ID is hidden from [currentOrEmpty] until the window
  /// closes — either committed (deleted) or cancelled (undo tapped).
  static final pendingDeleteId = ValueNotifier<String?>(null);

  static ValueNotifier<StoreState<List<Sale>>> get state => _store.state;
  static List<Sale>? get current => _store.current;

  static List<Sale> get currentOrEmpty {
    final all = _store.currentOrEmpty;
    final excluded = pendingDeleteId.value;
    if (excluded == null) return all;
    return all.where((s) => s.id != excluded).toList();
  }

  static void init() => _store.init();
  static void ensureSubscribed() => _store.ensureSubscribed();
  static void forceReset() => _store.forceReset();
  static void dispose() => _store.dispose();
}
