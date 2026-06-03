import 'package:firebase_auth/firebase_auth.dart';

import '../../buyers/repositories/buyer_repository.dart';
import '../../sales/repositories/sale_repository.dart';

class ResetAppService {
  final _salesRepo = SaleRepository();
  final _buyersRepo = BuyerRepository();

  Future<void> resetApp({bool deletePhotos = false}) async {
    await _salesRepo.deleteAllSales(deletePhotos: deletePhotos);
    await _buyersRepo.deleteAllBuyers();
    await FirebaseAuth.instance.signOut();
  }
}
