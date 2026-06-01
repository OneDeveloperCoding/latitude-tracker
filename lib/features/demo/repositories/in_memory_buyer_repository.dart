import 'dart:async';

import '../../buyers/models/buyer.dart';
import '../../buyers/models/buyer_address.dart';
import '../../buyers/repositories/buyer_repository.dart';
import '../demo_data.dart';

class InMemoryBuyerRepository implements BuyerRepository {
  final _buyers = <Buyer>[];
  final _addresses = <String, List<BuyerAddress>>{};
  final _buyerController = StreamController<List<Buyer>>.broadcast();
  final _addressControllers =
      <String, StreamController<List<BuyerAddress>>>{};

  StreamController<List<BuyerAddress>> _addressController(String buyerId) =>
      _addressControllers.putIfAbsent(
          buyerId, () => StreamController<List<BuyerAddress>>.broadcast());

  List<Buyer> get _sorted =>
      List.from(_buyers)..sort((a, b) => a.name.compareTo(b.name));

  void _emitBuyers() => _buyerController.add(_sorted);

  void _emitAddresses(String buyerId) => _addressController(buyerId)
      .add(List.from(_addresses[buyerId] ?? []));

  void seed() {
    _buyers
      ..clear()
      ..addAll(DemoData.buyers());
    _addresses
      ..clear()
      ..addAll(DemoData.addresses());
    _emitBuyers();
    for (final id in _addresses.keys) {
      _emitAddresses(id);
    }
  }

  void clear() {
    _buyers.clear();
    _addresses.clear();
    _emitBuyers();
    for (final id in _addressControllers.keys) {
      _addressControllers[id]!.add([]);
    }
  }

  @override
  Stream<List<Buyer>> watchBuyers() async* {
    yield _sorted;
    yield* _buyerController.stream;
  }

  @override
  Future<Buyer?> getBuyer(String id) async =>
      _buyers.where((b) => b.id == id).firstOrNull;

  @override
  Future<List<Buyer>> getAllBuyers() async => _sorted;

  @override
  Future<List<BuyerAddress>> getAllAddressesForBuyer(String buyerId) async =>
      List.from(_addresses[buyerId] ?? []);

  @override
  Stream<List<BuyerAddress>> watchAddresses(String buyerId) async* {
    yield List.from(_addresses[buyerId] ?? []);
    yield* _addressController(buyerId).stream;
  }

  @override
  Future<void> createBuyer(Buyer buyer) async {
    _buyers.add(buyer);
    _emitBuyers();
  }

  @override
  Future<void> updateBuyer(Buyer buyer) async {
    final idx = _buyers.indexWhere((b) => b.id == buyer.id);
    if (idx != -1) {
      _buyers[idx] = buyer;
      _emitBuyers();
    }
  }

  @override
  Future<void> deleteBuyer(String id) async {
    _buyers.removeWhere((b) => b.id == id);
    _addresses.remove(id);
    _emitBuyers();
  }

  @override
  Future<void> createAddress(String buyerId, BuyerAddress address) async {
    final list = _addresses.putIfAbsent(buyerId, () => []);
    if (address.isDefault) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].isDefault) list[i] = list[i].copyWith(isDefault: false);
      }
    }
    list.add(address);
    _emitAddresses(buyerId);
  }

  @override
  Future<void> updateAddress(String buyerId, BuyerAddress address) async {
    final list = _addresses[buyerId] ?? [];
    if (address.isDefault) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].id != address.id && list[i].isDefault) {
          list[i] = list[i].copyWith(isDefault: false);
        }
      }
    }
    final idx = list.indexWhere((a) => a.id == address.id);
    if (idx != -1) {
      list[idx] = address;
      _emitAddresses(buyerId);
    }
  }

  @override
  Future<void> deleteAddress(String buyerId, String addressId) async {
    _addresses[buyerId]?.removeWhere((a) => a.id == addressId);
    _emitAddresses(buyerId);
  }
}
