import 'package:latitude_tracker/features/demo/repositories/in_memory_repair_repository.dart';
import 'package:latitude_tracker/features/demo/repositories/in_memory_sale_repository.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/settings/repositories/catalogue_repository.dart';
import 'package:latitude_tracker/features/settings/services/category_service.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/sale_factory.dart';

// ---------------------------------------------------------------------------

class _ThrowingSaleRepo extends InMemorySaleRepository {
  @override
  Future<void> renameCategory(String oldName, String newName) =>
      Future.error(Exception('sale repo failure'));
}

class _ThrowingRepairRepo extends InMemoryRepairRepository {
  @override
  Future<void> renameCategory(String oldName, String newName) =>
      Future.error(Exception('repair repo failure'));
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
  createdAt: DateTime(2026),
);

CategoryService _makeService({
  InMemorySaleRepository? saleRepo,
  InMemoryRepairRepository? repairRepo,
  InMemoryCatalogueRepository? catalogueRepo,
}) => CategoryService(
  saleRepo: saleRepo ?? InMemorySaleRepository(),
  repairRepo: repairRepo ?? InMemoryRepairRepository(),
  catalogueRepo: catalogueRepo ?? InMemoryCatalogueRepository(),
);

void main() {
  group('renameCategory', () {
    test('updates SaleItem categories to new name', () async {
      final saleRepo = InMemorySaleRepository();
      final service = _makeService(saleRepo: saleRepo);

      await saleRepo.createSale(_saleWithCategory('Colares'));
      await saleRepo.createSale(_saleWithCategory('Brincos'));

      await service.renameCategory('Colares', 'Colares de Prata');

      final sales = await saleRepo.getSalesForYear(2026);
      final categories = sales
          .expand((s) => s.items.map((i) => i.category))
          .toSet();
      expect(categories, containsAll(['Colares de Prata', 'Brincos']));
      expect(categories, isNot(contains('Colares')));
    });

    test('updates Repair itemCategory to new name', () async {
      final repairRepo = InMemoryRepairRepository();
      final service = _makeService(repairRepo: repairRepo);

      await repairRepo.createRepair(_repairWithCategory('Colares'));
      await repairRepo.createRepair(_repairWithCategory('Chapéus'));

      await service.renameCategory('Colares', 'Colares de Ouro');

      final repairs = await repairRepo.getRepairsForYear(2026);
      final categories = repairs.map((r) => r.itemCategory).toSet();
      expect(categories, containsAll(['Colares de Ouro', 'Chapéus']));
      expect(categories, isNot(contains('Colares')));
    });

    test('does not affect records using a different category', () async {
      final saleRepo = InMemorySaleRepository();
      final repairRepo = InMemoryRepairRepository();
      final service = _makeService(saleRepo: saleRepo, repairRepo: repairRepo);

      await saleRepo.createSale(_saleWithCategory('Brincos'));
      await repairRepo.createRepair(_repairWithCategory('Brincos'));

      await service.renameCategory('Colares', 'Colares Novos');

      final sales = await saleRepo.getSalesForYear(2026);
      expect(sales.first.items.first.category, 'Brincos');

      final repairs = await repairRepo.getRepairsForYear(2026);
      expect(repairs.first.itemCategory, 'Brincos');
    });

    test('also renames hidden category entry', () async {
      final catalogueRepo = InMemoryCatalogueRepository();
      await catalogueRepo.saveHiddenCategories(['Colares', 'Pins']);
      final service = _makeService(catalogueRepo: catalogueRepo);

      await service.renameCategory('Colares', 'Colares Novos');

      final hidden = await catalogueRepo.fetchHiddenCategories();
      expect(hidden, containsAll(['Colares Novos', 'Pins']));
      expect(hidden, isNot(contains('Colares')));
    });

    // Both repos run concurrently via Future.wait, so the non-throwing repo
    // always commits — its async body executes synchronously at call time,
    // before Future.wait propagates any error. The catalogue is the only
    // step that is deterministically skipped on any repo failure.
    test(
      'saleRepo failure — repairRepo still runs, catalogue not updated',
      () async {
        final repairRepo = InMemoryRepairRepository();
        final catalogueRepo = InMemoryCatalogueRepository();
        await repairRepo.createRepair(_repairWithCategory('Colares'));
        await catalogueRepo.saveHiddenCategories(['Colares']);
        final service = _makeService(
          saleRepo: _ThrowingSaleRepo(),
          repairRepo: repairRepo,
          catalogueRepo: catalogueRepo,
        );

        await expectLater(
          service.renameCategory('Colares', 'Colares Novos'),
          throwsException,
        );

        final repairs = await repairRepo.getRepairsForYear(2026);
        expect(repairs.first.itemCategory, 'Colares Novos');
        final hidden = await catalogueRepo.fetchHiddenCategories();
        expect(hidden, ['Colares']);
      },
    );

    test(
      'repairRepo failure — saleRepo still runs, catalogue not updated',
      () async {
        final saleRepo = InMemorySaleRepository();
        final catalogueRepo = InMemoryCatalogueRepository();
        await saleRepo.createSale(_saleWithCategory('Colares'));
        await catalogueRepo.saveHiddenCategories(['Colares']);
        final service = _makeService(
          saleRepo: saleRepo,
          repairRepo: _ThrowingRepairRepo(),
          catalogueRepo: catalogueRepo,
        );

        await expectLater(
          service.renameCategory('Colares', 'Colares Novos'),
          throwsException,
        );

        final sales = await saleRepo.getSalesForYear(2026);
        expect(sales.first.items.first.category, 'Colares Novos');
        final hidden = await catalogueRepo.fetchHiddenCategories();
        expect(hidden, ['Colares']);
      },
    );

    test('hidden list unchanged when renamed category is not hidden', () async {
      final catalogueRepo = InMemoryCatalogueRepository();
      await catalogueRepo.saveHiddenCategories(['Pins']);
      final service = _makeService(catalogueRepo: catalogueRepo);

      await service.renameCategory('Colares', 'Colares Novos');

      final hidden = await catalogueRepo.fetchHiddenCategories();
      expect(hidden, ['Pins']);
    });
  });

  group('hideCategory / unhideCategory', () {
    test('adds category to hidden list', () async {
      final catalogueRepo = InMemoryCatalogueRepository();
      await catalogueRepo.saveHiddenCategories(['Pins']);
      final service = _makeService(catalogueRepo: catalogueRepo);

      await service.hideCategory('Brincos');

      final hidden = await catalogueRepo.fetchHiddenCategories();
      expect(hidden, containsAll(['Pins', 'Brincos']));
    });

    test('removes category from hidden list', () async {
      final catalogueRepo = InMemoryCatalogueRepository();
      await catalogueRepo.saveHiddenCategories(['Pins', 'Brincos']);
      final service = _makeService(catalogueRepo: catalogueRepo);

      await service.unhideCategory('Brincos');

      final hidden = await catalogueRepo.fetchHiddenCategories();
      expect(hidden, ['Pins']);
      expect(hidden, isNot(contains('Brincos')));
    });

    test('calling hideCategory twice does not duplicate the entry', () async {
      final catalogueRepo = InMemoryCatalogueRepository();
      final service = _makeService(catalogueRepo: catalogueRepo);

      await service.hideCategory('Brincos');
      await service.hideCategory('Brincos');

      final hidden = await catalogueRepo.fetchHiddenCategories();
      expect(hidden, hasLength(1));
      expect(hidden, ['Brincos']);
    });
  });

  group('deleteCategory', () {
    test('removes category from hidden list', () async {
      final catalogueRepo = InMemoryCatalogueRepository();
      await catalogueRepo.saveHiddenCategories(['Colares', 'Pins']);
      final service = _makeService(catalogueRepo: catalogueRepo);

      await service.deleteCategory('Colares');

      final hidden = await catalogueRepo.fetchHiddenCategories();
      expect(hidden, ['Pins']);
    });

    test('no-op when category not in hidden list', () async {
      final catalogueRepo = InMemoryCatalogueRepository();
      await catalogueRepo.saveHiddenCategories(['Pins']);
      final service = _makeService(catalogueRepo: catalogueRepo);

      await service.deleteCategory('Stickers');

      final hidden = await catalogueRepo.fetchHiddenCategories();
      expect(hidden, ['Pins']);
    });
  });
}
