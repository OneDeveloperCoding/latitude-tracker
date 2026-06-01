import 'dart:async';

import '../../sales/models/sale.dart';
import '../demo_data.dart';

class InMemorySaleRepository {
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

  Stream<List<Sale>> watchSales() async* {
    yield _sorted;
    yield* _controller.stream
        .map((_) => _sorted);
  }

  Stream<Sale?> watchSale(String id) async* {
    yield _sales.where((s) => s.id == id).firstOrNull;
    yield* _controller.stream
        .map((_) => _sales.where((s) => s.id == id).firstOrNull);
  }

  Stream<List<Sale>> watchSalesForBuyer(String buyerId) async* {
    yield _salesForBuyer(buyerId);
    yield* _controller.stream.map((_) => _salesForBuyer(buyerId));
  }

  List<Sale> _salesForBuyer(String buyerId) =>
      _sales.where((s) => s.buyerId == buyerId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<List<Sale>> getSalesForBuyer(String buyerId) async =>
      _salesForBuyer(buyerId);

  Future<List<Sale>> getSalesForYear(int year) async =>
      _sales.where((s) => s.createdAt.year == year).toList();

  Future<void> createSale(Sale sale) async {
    _sales.add(sale);
    _emit();
  }

  Future<void> updateSale(Sale sale) async {
    final idx = _sales.indexWhere((s) => s.id == sale.id);
    if (idx != -1) {
      _sales[idx] = sale;
      _emit();
    }
  }

  Future<void> deleteSale(String id) async {
    _sales.removeWhere((s) => s.id == id);
    _emit();
  }

  Future<void> deleteAllSalesForYear(int year,
      {bool deletePhotos = false}) async {
    _sales.removeWhere((s) => s.createdAt.year == year);
    _emit();
  }
}
