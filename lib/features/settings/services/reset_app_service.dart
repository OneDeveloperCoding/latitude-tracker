import 'package:firebase_auth/firebase_auth.dart';

import '../../buyers/repositories/buyer_repository.dart';
import '../../repairs/repositories/repair_repository.dart';
import '../../sales/repositories/sale_repository.dart';
import '../repositories/catalogue_repository.dart';

class ResetAppService {
  final _salesRepo = SaleRepository();
  final _buyersRepo = BuyerRepository();
  final _repairsRepo = RepairRepository();
  final _catalogueRepo = CatalogueRepository();

  Future<void> resetApp({bool deletePhotos = false}) async {
    await _salesRepo.deleteAllSales(deletePhotos: deletePhotos);
    await _repairsRepo.deleteAllRepairs(deletePhotos: deletePhotos);
    await _buyersRepo.deleteAllBuyers();
    await _catalogueRepo.saveHiddenCategories([]);
    await FirebaseAuth.instance.signOut();
  }
}
