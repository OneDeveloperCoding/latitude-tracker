import 'package:flutter/foundation.dart';
import 'package:latitude_tracker/core/store/store_state.dart';
import 'package:latitude_tracker/core/store/stream_store.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/repositories/sale_repository.dart';

class SalesStore {
  SalesStore._();

  static final _store = StreamStore<Sale>(() => SaleRepository().watchSales());

  // IDs of sales hidden during their undo window (deleted from Firestore only
  // after the snackbar expires). Using a Set so concurrent deletions each
  // track their own ID without clobbering one another.
  static final _pendingDeleteIds = ValueNotifier<Set<String>>({});

  // Derived state: Firestore list filtered by _pendingDeleteIds.
  // All subscribers get the correct filtered snapshot automatically.
  static final _derivedState =
      ValueNotifier<StoreState<List<Sale>>>(const StoreLoading());
  static bool _listenersAdded = false;

  static void _recompute() {
    final raw = _store.state.value;
    final excluded = _pendingDeleteIds.value;
    _derivedState.value = excluded.isEmpty
        ? raw
        : switch (raw) {
            StoreLoaded(:final data) =>
              StoreLoaded(data.where((s) => !excluded.contains(s.id)).toList()),
            _ => raw,
          };
  }

  static void _hookListeners() {
    if (_listenersAdded) return;
    _listenersAdded = true;
    _store.state.addListener(_recompute);
    _pendingDeleteIds.addListener(_recompute);
  }

  /// Hides [id] from [state] / [current] / [currentOrEmpty] until
  /// [clearPendingDelete] is called.  Safe to call while another deletion's
  /// undo window is open — each ID is tracked independently.
  static void markPendingDelete(String id) =>
      _pendingDeleteIds.value = {..._pendingDeleteIds.value, id};

  /// Removes [id] from the pending-delete set.  Called both on undo (cancel)
  /// and after a successful Firestore delete (commit).
  static void clearPendingDelete(String id) =>
      _pendingDeleteIds.value = {..._pendingDeleteIds.value}..remove(id);

  static ValueNotifier<StoreState<List<Sale>>> get state => _derivedState;

  static List<Sale>? get current => switch (_derivedState.value) {
        StoreLoaded(:final data) => data,
        _ => null,
      };

  static List<Sale> get currentOrEmpty => current ?? [];

  static void init() {
    _hookListeners();
    _store.init();
  }

  static void ensureSubscribed() {
    _hookListeners();
    _store.ensureSubscribed();
  }

  static void forceReset() {
    _pendingDeleteIds.value = {};
    _store.forceReset();
  }

  static void dispose() => _store.dispose();
}
