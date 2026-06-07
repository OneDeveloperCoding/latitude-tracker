import '../../repairs/repositories/repair_repository.dart';
import '../../sales/repositories/sale_repository.dart';
import '../repositories/catalogue_repository.dart';

class CategoryService {
  final SaleRepository _saleRepo;
  final RepairRepository _repairRepo;
  final CatalogueRepository _catalogueRepo;

  CategoryService({
    SaleRepository? saleRepo,
    RepairRepository? repairRepo,
    CatalogueRepository? catalogueRepo,
  })  : _saleRepo = saleRepo ?? SaleRepository(),
        _repairRepo = repairRepo ?? RepairRepository(),
        _catalogueRepo = catalogueRepo ?? CatalogueRepository();

  Future<List<String>> fetchHiddenCategories() =>
      _catalogueRepo.fetchHiddenCategories();

  /// Renames [oldName] to [newName] across all SaleItems, Repairs, and the
  /// hidden list. Returns the updated hidden list so callers can refresh
  /// local state without a second round-trip.
  Future<List<String>> renameCategory(String oldName, String newName) async {
    final currentHidden = await _catalogueRepo.fetchHiddenCategories();
    final updatedHidden = currentHidden.contains(oldName)
        ? [...currentHidden.where((c) => c != oldName), newName]
        : currentHidden;

    // Non-atomic: if an earlier step succeeds and a later one throws, the
    // earlier writes are already committed. Ordered data-before-metadata so
    // a failure in the catalogue step (least critical) doesn't leave Sale /
    // Repair records inconsistent with each other.
    await _saleRepo.renameCategory(oldName, newName);
    await _repairRepo.renameCategory(oldName, newName);
    await _catalogueRepo.saveHiddenCategories(updatedHidden);

    return List<String>.from(updatedHidden);
  }

  Future<void> hideCategory(String name) =>
      _catalogueRepo.addHiddenCategory(name);

  Future<void> unhideCategory(String name) =>
      _catalogueRepo.removeHiddenCategory(name);

  // Deleting a category removes it from the hidden list — same operation as
  // unhide, but expressed as a separate method to preserve semantic clarity
  // at the call site.
  Future<void> deleteCategory(String name) =>
      _catalogueRepo.removeHiddenCategory(name);
}
