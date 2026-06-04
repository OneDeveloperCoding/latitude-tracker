import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/demo/repositories/in_memory_repair_repository.dart';
import 'package:latitude_tracker/features/demo/repositories/in_memory_sale_repository.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/sale_factory.dart';

// ---------------------------------------------------------------------------
// Lightweight stand-ins that avoid Firebase and DemoMode static state.
// ---------------------------------------------------------------------------

class _TestCatalogueRepo {
  List<String> _hidden = [];

  Future<List<String>> fetchHiddenCategories() async =>
      List.unmodifiable(_hidden);

  Future<void> saveHiddenCategories(List<String> hidden) async =>
      _hidden = List.of(hidden);
}

// Thin wrapper that wires the three repos together like CategoryService does.
class _TestService {
  final InMemorySaleRepository saleRepo;
  final InMemoryRepairRepository repairRepo;
  final _TestCatalogueRepo catalogueRepo;

  _TestService({
    required this.saleRepo,
    required this.repairRepo,
    required this.catalogueRepo,
  });

  Future<void> renameCategory(
    String oldName,
    String newName,
    List<String> currentHidden,
  ) async {
    final updatedHidden = currentHidden.contains(oldName)
        ? [...currentHidden.where((c) => c != oldName), newName]
        : currentHidden;
    await Future.wait([
      saleRepo.renameCategory(oldName, newName),
      repairRepo.renameCategory(oldName, newName),
      catalogueRepo.saveHiddenCategories(updatedHidden),
    ]);
  }

  Future<void> hideCategory(String name, List<String> currentHidden) =>
      catalogueRepo.saveHiddenCategories([...currentHidden, name]);

  Future<void> unhideCategory(String name, List<String> currentHidden) =>
      catalogueRepo.saveHiddenCategories(
        currentHidden.where((c) => c != name).toList(),
      );

  Future<void> deleteCategory(String name, List<String> currentHidden) =>
      catalogueRepo.saveHiddenCategories(
        currentHidden.where((c) => c != name).toList(),
      );
}

// ---------------------------------------------------------------------------

Sale _saleWithCategory(String category) => makeSale(category: category);

Repair _repairWithCategory(String category) => Repair(
      id: const Uuid().v4(),
      itemCategory: category,
      itemDescription: 'Test item',
      problemDescription: 'Test problem',
      status: RepairStatus.received,
      payment: const SalePayment(
        status: PaymentStatus.unpaid,
        method: PaymentMethod.mbWay,
      ),
      returnDelivery: const RepairReturnDelivery(
        type: DeliveryType.pickup,
        status: ShipmentStatus.pending,
      ),
      freeTextContact: 'Test contact',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('renameCategory', () {
    test('updates SaleItem categories to new name', () async {
      final saleRepo = InMemorySaleRepository();
      final repairRepo = InMemoryRepairRepository();
      final catalogueRepo = _TestCatalogueRepo();
      final service = _TestService(
        saleRepo: saleRepo,
        repairRepo: repairRepo,
        catalogueRepo: catalogueRepo,
      );

      await saleRepo.createSale(_saleWithCategory('Colares'));
      await saleRepo.createSale(_saleWithCategory('Brincos'));

      await service.renameCategory('Colares', 'Colares de Prata', []);

      final sales = await saleRepo.getSalesForYear(2026);
      final categories =
          sales.expand((s) => s.items.map((i) => i.category)).toSet();
      expect(categories, containsAll(['Colares de Prata', 'Brincos']));
      expect(categories, isNot(contains('Colares')));
    });

    test('updates Repair itemCategory to new name', () async {
      final saleRepo = InMemorySaleRepository();
      final repairRepo = InMemoryRepairRepository();
      final catalogueRepo = _TestCatalogueRepo();
      final service = _TestService(
        saleRepo: saleRepo,
        repairRepo: repairRepo,
        catalogueRepo: catalogueRepo,
      );

      await repairRepo.createRepair(_repairWithCategory('Colares'));
      await repairRepo.createRepair(_repairWithCategory('Chapéus'));

      await service.renameCategory('Colares', 'Colares de Ouro', []);

      final repairs = await repairRepo.getRepairsForYear(2026);
      final categories = repairs.map((r) => r.itemCategory).toSet();
      expect(categories, containsAll(['Colares de Ouro', 'Chapéus']));
      expect(categories, isNot(contains('Colares')));
    });

    test('does not affect records using a different category', () async {
      final saleRepo = InMemorySaleRepository();
      final repairRepo = InMemoryRepairRepository();
      final catalogueRepo = _TestCatalogueRepo();
      final service = _TestService(
        saleRepo: saleRepo,
        repairRepo: repairRepo,
        catalogueRepo: catalogueRepo,
      );

      await saleRepo.createSale(_saleWithCategory('Brincos'));
      await repairRepo.createRepair(_repairWithCategory('Brincos'));

      await service.renameCategory('Colares', 'Colares Novos', []);

      final sales = await saleRepo.getSalesForYear(2026);
      expect(sales.first.items.first.category, 'Brincos');

      final repairs = await repairRepo.getRepairsForYear(2026);
      expect(repairs.first.itemCategory, 'Brincos');
    });

    test('also renames hidden category entry', () async {
      final saleRepo = InMemorySaleRepository();
      final repairRepo = InMemoryRepairRepository();
      final catalogueRepo = _TestCatalogueRepo();
      final service = _TestService(
        saleRepo: saleRepo,
        repairRepo: repairRepo,
        catalogueRepo: catalogueRepo,
      );

      await service.renameCategory('Colares', 'Colares Novos', ['Colares', 'Pins']);

      final hidden = await catalogueRepo.fetchHiddenCategories();
      expect(hidden, containsAll(['Colares Novos', 'Pins']));
      expect(hidden, isNot(contains('Colares')));
    });

    test('hidden list unchanged when renamed category is not hidden', () async {
      final saleRepo = InMemorySaleRepository();
      final repairRepo = InMemoryRepairRepository();
      final catalogueRepo = _TestCatalogueRepo();
      final service = _TestService(
        saleRepo: saleRepo,
        repairRepo: repairRepo,
        catalogueRepo: catalogueRepo,
      );

      await service.renameCategory('Colares', 'Colares Novos', ['Pins']);

      final hidden = await catalogueRepo.fetchHiddenCategories();
      expect(hidden, ['Pins']);
    });
  });

  group('hideCategory / unhideCategory', () {
    test('adds category to hidden list', () async {
      final service = _TestService(
        saleRepo: InMemorySaleRepository(),
        repairRepo: InMemoryRepairRepository(),
        catalogueRepo: _TestCatalogueRepo(),
      );

      await service.hideCategory('Brincos', ['Pins']);

      final hidden =
          await service.catalogueRepo.fetchHiddenCategories();
      expect(hidden, containsAll(['Pins', 'Brincos']));
    });

    test('removes category from hidden list', () async {
      final service = _TestService(
        saleRepo: InMemorySaleRepository(),
        repairRepo: InMemoryRepairRepository(),
        catalogueRepo: _TestCatalogueRepo(),
      );

      await service.unhideCategory('Brincos', ['Pins', 'Brincos']);

      final hidden =
          await service.catalogueRepo.fetchHiddenCategories();
      expect(hidden, ['Pins']);
      expect(hidden, isNot(contains('Brincos')));
    });
  });

  group('deleteCategory', () {
    test('removes category from hidden list', () async {
      final service = _TestService(
        saleRepo: InMemorySaleRepository(),
        repairRepo: InMemoryRepairRepository(),
        catalogueRepo: _TestCatalogueRepo(),
      );

      await service.deleteCategory('Colares', ['Colares', 'Pins']);

      final hidden =
          await service.catalogueRepo.fetchHiddenCategories();
      expect(hidden, ['Pins']);
    });

    test('no-op when category not in hidden list', () async {
      final service = _TestService(
        saleRepo: InMemorySaleRepository(),
        repairRepo: InMemoryRepairRepository(),
        catalogueRepo: _TestCatalogueRepo(),
      );

      await service.deleteCategory('Stickers', ['Pins']);

      final hidden =
          await service.catalogueRepo.fetchHiddenCategories();
      expect(hidden, ['Pins']);
    });
  });
}
