import 'dart:async';

import '../../sales/models/sale.dart';
import '../../sales/repositories/sale_repository.dart';
import '../demo_data.dart';

class InMemorySaleRepository implements SaleRepository {
  final _sales = <Sale>[];
  final _controller = StreamController<List<Sale>>.broadcast();

  void _emit() => _controller.add(List.from(_sales));

  void seed() {
    _sales
      ..clear()
      ..addAll(DemoData.sales());
    _emit();
  }

  void clear() {
    _sales.clear();
    _emit();
  }

  List<Sale> get _sorted =>
      List.from(_sales)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<Sale>> watchSales() async* {
    yield _sorted;
    yield* _controller.stream.map((_) => _sorted);
  }

  @override
  Stream<Sale?> watchSale(String id) async* {
    yield _sales.where((s) => s.id == id).firstOrNull;
    yield* _controller.stream
        .map((_) => _sales.where((s) => s.id == id).firstOrNull);
  }

  @override
  Stream<List<Sale>> watchSalesForBuyer(String buyerId) async* {
    yield _salesForBuyer(buyerId);
    yield* _controller.stream.map((_) => _salesForBuyer(buyerId));
  }

  List<Sale> _salesForBuyer(String buyerId) =>
      _sales.where((s) => s.buyerId == buyerId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<Sale>> getSalesForBuyer(String buyerId) async =>
      _salesForBuyer(buyerId);

  @override
  Future<List<Sale>> getSalesForYear(int year) async =>
      _sales.where((s) => s.createdAt.year == year).toList();

  @override
  Future<void> createSale(Sale sale) async {
    _sales.add(sale);
    _emit();
  }

  @override
  Future<bool> createSaleIfNotExists(Sale sale) async {
    if (_sales.any((s) => s.id == sale.id)) return false;
    await createSale(sale);
    return true;
  }

  @override
  Future<void> updateSale(Sale sale) async {
    final idx = _sales.indexWhere((s) => s.id == sale.id);
    if (idx != -1) {
      _sales[idx] = sale;
      _emit();
    }
  }

  @override
  Future<void> deleteSale(String id) async {
    _sales.removeWhere((s) => s.id == id);
    _emit();
  }

  @override
  Future<void> deleteAllSalesForYear(int year,
      {bool deletePhotos = false}) async {
    _sales.removeWhere((s) => s.createdAt.year == year);
    _emit();
  }

  @override
  Future<void> deleteAllSales({bool deletePhotos = false}) async {
    _sales.clear();
    _emit();
  }

  @override
  Future<void> renameCategory(String oldName, String newName) async {
    for (var i = 0; i < _sales.length; i++) {
      final sale = _sales[i];
      if (!sale.items.any((item) => item.category == oldName)) continue;
      _sales[i] = sale.copyWith(
        items: sale.items
            .map((item) => item.category == oldName
                ? item.copyWith(category: newName)
                : item)
            .toList(),
      );
    }
    _emit();
  }
}
