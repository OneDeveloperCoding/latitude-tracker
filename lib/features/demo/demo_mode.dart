import 'package:flutter/foundation.dart';

import 'repositories/in_memory_buyer_repository.dart';
import 'repositories/in_memory_sale_repository.dart';

class DemoMode {
  DemoMode._();

  static final active = ValueNotifier<bool>(false);

  static final InMemorySaleRepository saleRepo = InMemorySaleRepository();
  static final InMemoryBuyerRepository buyerRepo = InMemoryBuyerRepository();

  static void enter() {
    saleRepo.seed();
    buyerRepo.seed();
    active.value = true;
  }

  static void exit() {
    active.value = false;
    saleRepo.clear();
    buyerRepo.clear();
  }
}
