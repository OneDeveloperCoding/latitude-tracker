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

  /// Renames [oldName] to [newName] across all SaleItems, Repairs, and the
  /// hidden list. Runs in parallel where possible.
  Future<void> renameCategory(
    String oldName,
    String newName,
    List<String> currentHidden,
  ) async {
    final updatedHidden = currentHidden.contains(oldName)
        ? [...currentHidden.where((c) => c != oldName), newName]
        : currentHidden;

    await Future.wait([
      _saleRepo.renameCategory(oldName, newName),
      _repairRepo.renameCategory(oldName, newName),
      _catalogueRepo.saveHiddenCategories(updatedHidden),
    ]);
  }

  Future<void> hideCategory(
    String name,
    List<String> currentHidden,
  ) =>
      currentHidden.contains(name)
          ? Future.value()
          : _catalogueRepo.saveHiddenCategories([...currentHidden, name]);

  Future<void> unhideCategory(
    String name,
    List<String> currentHidden,
  ) =>
      _catalogueRepo.saveHiddenCategories(
        currentHidden.where((c) => c != name).toList(),
      );

  Future<void> deleteCategory(
    String name,
    List<String> currentHidden,
  ) =>
      unhideCategory(name, currentHidden);
}
