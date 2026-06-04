import 'package:flutter/foundation.dart';

import 'repositories/in_memory_buyer_repository.dart';
import 'repositories/in_memory_repair_repository.dart';
import 'repositories/in_memory_sale_repository.dart';

class DemoMode {
  DemoMode._();

  static final active = ValueNotifier<bool>(false);

  // Fires once each time demo mode is entered; MainNav listens and shows the tutorial.
  static final pendingTutorial = ValueNotifier<bool>(false);

  static final InMemorySaleRepository saleRepo = InMemorySaleRepository();
  static final InMemoryBuyerRepository buyerRepo = InMemoryBuyerRepository();
  static final InMemoryRepairRepository repairRepo = InMemoryRepairRepository();

  static void enter() {
    saleRepo.seed();
    buyerRepo.seed();
    repairRepo.seed();
    active.value = true;
    pendingTutorial.value = true;
  }

  static void exit() {
    active.value = false;
    saleRepo.clear();
    buyerRepo.clear();
    repairRepo.clear();
  }
}
