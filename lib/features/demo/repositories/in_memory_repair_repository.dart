import 'dart:async';

import 'package:latitude_tracker/features/demo/demo_data.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/repairs/repositories/repair_repository.dart';

class InMemoryRepairRepository implements RepairRepository {
  final _repairs = <Repair>[];
  final _controller = StreamController<List<Repair>>.broadcast();

  void _emit() => _controller.add(List.from(_repairs));

  void seed() {
    _repairs
      ..clear()
      ..addAll(DemoData.repairs());
    _emit();
  }

  void clear() {
    _repairs.clear();
    _emit();
  }

  List<Repair> get _sorted =>
      List.from(_repairs)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<Repair>> watchRepairs() async* {
    yield _sorted;
    yield* _controller.stream.map((_) => _sorted);
  }

  @override
  Stream<Repair?> watchRepair(String id) async* {
    yield _repairs.where((r) => r.id == id).firstOrNull;
    yield* _controller.stream.map(
      (_) => _repairs.where((r) => r.id == id).firstOrNull,
    );
  }

  @override
  Stream<List<Repair>> watchRepairsForSale(String saleId) async* {
    yield _repairsForSale(saleId);
    yield* _controller.stream.map((_) => _repairsForSale(saleId));
  }

  List<Repair> _repairsForSale(String saleId) =>
      _repairs.where((r) => r.linkedSaleId == saleId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> createRepair(Repair repair) async {
    _repairs.add(repair);
    _emit();
  }

  @override
  Future<bool> createRepairIfNotExists(Repair repair) async {
    if (_repairs.any((r) => r.id == repair.id)) return false;
    await createRepair(repair);
    return true;
  }

  @override
  Future<void> updateRepair(Repair repair) async {
    final idx = _repairs.indexWhere((r) => r.id == repair.id);
    if (idx != -1) {
      _repairs[idx] = repair;
      _emit();
    }
  }

  @override
  Future<void> deleteRepair(String id) async {
    _repairs.removeWhere((r) => r.id == id);
    _emit();
  }

  @override
  Future<List<Repair>> getRepairsForYear(int year) async =>
      _repairs.where((r) => r.createdAt.year == year).toList();

  @override
  Future<void> deleteAllRepairsForYear(
    int year, {
    bool deletePhotos = false,
  }) async {
    _repairs.removeWhere((r) => r.createdAt.year == year);
    _emit();
  }

  @override
  Future<void> deleteAllRepairs({bool deletePhotos = false}) async {
    _repairs.clear();
    _emit();
  }

  @override
  Future<void> renameCategory(String oldName, String newName) async {
    for (var i = 0; i < _repairs.length; i++) {
      if (_repairs[i].itemCategory == oldName) {
        _repairs[i] = _repairs[i].copyWith(itemCategory: newName);
      }
    }
    _emit();
  }
}
