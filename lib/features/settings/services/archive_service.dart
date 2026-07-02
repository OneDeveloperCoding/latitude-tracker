import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latitude_tracker/features/buyers/models/buyer.dart';
import 'package:latitude_tracker/features/buyers/models/buyer_address.dart';
import 'package:latitude_tracker/features/buyers/repositories/buyer_repository.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/repairs/repositories/repair_repository.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/repositories/sale_repository.dart';
import 'package:latitude_tracker/features/settings/services/drive_service_helper.dart';
import 'package:path_provider/path_provider.dart';

// Version 1.1 adds a `repairs` array. Version 1.2 adds `handDelivery` type.
// Version 1.3 expands components with `photoUrls` and `notes`.
// Version 1.4 adds `quantity` to each ComponentItem (older archives
// default to 1).
// Version 1.5 adds `shippedAt` to the shipment object (older archives
// default to null).
const _kCurrentArchiveVersion = '1.5';
const _kSupportedArchiveVersions = {'1.0', '1.1', '1.2', '1.3', '1.4', '1.5'};

class ImportResult {
  const ImportResult({
    required this.salesImported,
    required this.buyersImported,
    required this.repairsImported,
    required this.skipped,
  });
  final int salesImported;
  final int buyersImported;
  final int repairsImported;
  final int skipped;
}

class ArchiveService {
  ArchiveService({
    SaleRepository? salesRepo,
    BuyerRepository? buyersRepo,
    RepairRepository? repairsRepo,
  }) : _salesRepoOverride = salesRepo,
       _buyersRepoOverride = buyersRepo,
       _repairsRepoOverride = repairsRepo;
  final SaleRepository? _salesRepoOverride;
  final BuyerRepository? _buyersRepoOverride;
  final RepairRepository? _repairsRepoOverride;

  // Lazy so Firebase isn't accessed until the first actual read/write call,
  // allowing the version check to throw before any Firebase interaction.
  // The override fields are needed because late-field initialisers can only
  // close over `this`, so the injected value must be stored as a field first.
  late final SaleRepository _salesRepo = _salesRepoOverride ?? SaleRepository();
  late final BuyerRepository _buyersRepo =
      _buyersRepoOverride ?? BuyerRepository();
  late final RepairRepository _repairsRepo =
      _repairsRepoOverride ?? RepairRepository();

  // Fetches all buyers and their addresses as serialisable maps.
  // Call once before a multi-year export loop to avoid redundant Firestore
  // reads — buyers are not year-scoped, so re-fetching per year is wasteful.
  Future<List<Map<String, dynamic>>> fetchBuyersData() async {
    final buyers = await _buyersRepo.getAllBuyers();
    final result = <Map<String, dynamic>>[];
    for (final buyer in buyers) {
      final addresses = await _buyersRepo.getAllAddressesForBuyer(buyer.id);
      result.add({
        'id': buyer.id,
        ...buyer.toFirestore(),
        'addresses': addresses
            .map((a) => {'id': a.id, ...a.toFirestore()})
            .toList(),
      });
    }
    return result;
  }

  // Pass [cachedBuyers] (from [fetchBuyersData]) when exporting multiple years
  // in a loop — avoids re-fetching the buyer list for every year.
  Future<File> exportYear(
    int year, {
    List<Map<String, dynamic>>? cachedBuyers,
  }) async {
    final sales = await _salesRepo.getSalesForYear(year);
    final repairs = await _repairsRepo.getRepairsForYear(year);
    final buyersData = cachedBuyers ?? await fetchBuyersData();

    final archive = _toJsonSafe({
      'version': _kCurrentArchiveVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'year': year,
      'sales': sales.map((s) => {'id': s.id, ...s.toFirestore()}).toList(),
      'repairs': repairs.map((r) => {'id': r.id, ...r.toFirestore()}).toList(),
      'buyers': buyersData,
    });

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${DriveServiceHelper.backupFileName(year)}',
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(archive),
    );
    return file;
  }

  // Reimports an archive into Firestore. Documents that already exist are
  // skipped — this makes it safe to run multiple times on the same archive.
  // Throws [FormatException] if the archive version is not supported.
  Future<ImportResult> importArchive(Map<String, dynamic> archive) async {
    final version = archive['version'] as String?;
    if (version == null || !_kSupportedArchiveVersions.contains(version)) {
      throw FormatException(
        'Unsupported archive version: $version. '
        'Supported: ${_kSupportedArchiveVersions.join(', ')}.',
      );
    }

    final sales =
        (archive['sales'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final repairs =
        (archive['repairs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final buyers =
        (archive['buyers'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    var salesImported = 0;
    var repairsImported = 0;
    var buyersImported = 0;
    var skipped = 0;

    for (final buyerMap in buyers) {
      final buyerId = buyerMap['id'] as String?;
      if (buyerId == null || buyerId.isEmpty) continue;
      final buyer = Buyer.fromArchiveMap(buyerMap);
      final addresses =
          (buyerMap['addresses'] as List?)
              ?.cast<Map<String, dynamic>>()
              .where(
                (a) =>
                    (a['id'] as String?) != null &&
                    (a['id'] as String).isNotEmpty,
              )
              .map((a) => BuyerAddress.fromArchiveMap(buyer.id, a))
              .toList() ??
          [];
      final created = await _buyersRepo.createBuyerIfNotExists(
        buyer,
        addresses,
      );
      if (created) {
        buyersImported++;
      } else {
        skipped++;
      }
    }

    for (final saleMap in sales) {
      final saleId = saleMap['id'] as String?;
      if (saleId == null || saleId.isEmpty) continue;
      final sale = Sale.fromArchiveMap(saleMap);
      final created = await _salesRepo.createSaleIfNotExists(sale);
      if (created) {
        salesImported++;
      } else {
        skipped++;
      }
    }

    for (final repairMap in repairs) {
      final repairId = repairMap['id'] as String?;
      if (repairId == null || repairId.isEmpty) continue;
      final repair = Repair.fromArchiveMap(repairMap);
      final created = await _repairsRepo.createRepairIfNotExists(repair);
      if (created) {
        repairsImported++;
      } else {
        skipped++;
      }
    }

    return ImportResult(
      salesImported: salesImported,
      buyersImported: buyersImported,
      repairsImported: repairsImported,
      skipped: skipped,
    );
  }

  // Firestore Timestamps are not JSON-serialisable — convert them to ISO
  // strings.
  static dynamic _toJsonSafe(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k as String, _toJsonSafe(v)));
    }
    if (value is List) return value.map(_toJsonSafe).toList();
    return value;
  }

  static Map<String, dynamic>? parseArchive(String jsonContent) {
    try {
      return jsonDecode(jsonContent) as Map<String, dynamic>;
    } on Object catch (_) {
      return null;
    }
  }
}
