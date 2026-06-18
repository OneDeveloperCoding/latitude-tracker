import 'package:flutter/foundation.dart';
import 'package:latitude_tracker/core/store/buyers_store.dart';
import 'package:latitude_tracker/core/store/repairs_store.dart';
import 'package:latitude_tracker/core/store/sales_store.dart';
import 'package:latitude_tracker/features/demo/repositories/in_memory_buyer_repository.dart';
import 'package:latitude_tracker/features/demo/repositories/in_memory_repair_repository.dart';
import 'package:latitude_tracker/features/demo/repositories/in_memory_sale_repository.dart';
import 'package:latitude_tracker/features/settings/repositories/catalogue_repository.dart';

class DemoMode {
  DemoMode._();

  static final active = ValueNotifier<bool>(false);

  // Fires once each time demo mode is entered; MainNav listens and shows the
  // tutorial.
  static final pendingTutorial = ValueNotifier<bool>(false);

  static final InMemorySaleRepository saleRepo = InMemorySaleRepository();
  static final InMemoryBuyerRepository buyerRepo = InMemoryBuyerRepository();
  static final InMemoryRepairRepository repairRepo = InMemoryRepairRepository();
  // Shared singleton so CategoryMaintenanceScreen and showCategoryPicker
  // read/write the same in-memory instance during a demo session.
  static final InMemoryCatalogueRepository catalogueRepo =
      InMemoryCatalogueRepository();

  static void enter() {
    saleRepo.seed();
    buyerRepo.seed();
    repairRepo.seed();
    // Reset stores before the rebuild so the new MainNav's init() finds
    // _sub == null and opens a fresh subscription to the InMemory backend.
    SalesStore.forceReset();
    BuyersStore.forceReset();
    RepairsStore.forceReset();
    active.value = true;
    pendingTutorial.value = true;
  }

  static void exit() {
    // Same rationale as enter(): reset before the rebuild so the new MainNav
    // gets a fresh Firestore subscription instead of the InMemory one.
    SalesStore.forceReset();
    BuyersStore.forceReset();
    RepairsStore.forceReset();
    active.value = false;
    saleRepo.clear();
    buyerRepo.clear();
    repairRepo.clear();
    catalogueRepo.clear();
  }
}
