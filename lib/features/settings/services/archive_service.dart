import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

import '../../buyers/models/buyer.dart';
import '../../buyers/models/buyer_address.dart';
import '../../buyers/repositories/buyer_repository.dart';
import '../../repairs/models/repair.dart';
import '../../repairs/repositories/repair_repository.dart';
import '../../sales/models/sale.dart';
import '../../sales/repositories/sale_repository.dart';

// Version 1.1 adds a `repairs` array. Version 1.2 adds `handDelivery` type.
// Version 1.3 expands components with `photoUrls` and `notes`.
// Version 1.4 adds `quantity` to each ComponentItem (older archives default to 1).
const _kCurrentArchiveVersion = '1.4';
const _kSupportedArchiveVersions = {'1.0', '1.1', '1.2', '1.3', '1.4'};

class ImportResult {
  final int salesImported;
  final int buyersImported;
  final int repairsImported;
  final int skipped;

  const ImportResult({
    required this.salesImported,
    required this.buyersImported,
    required this.repairsImported,
    required this.skipped,
  });
}

class ArchiveService {
  final SaleRepository? _salesRepoOverride;
  final BuyerRepository? _buyersRepoOverride;
  final RepairRepository? _repairsRepoOverride;

  // Lazy so Firebase isn't accessed until the first actual read/write call,
  // allowing the version check to throw before any Firebase interaction.
  // The override fields are needed because late-field initialisers can only
  // close over `this`, so the injected value must be stored as a field first.
  late final _salesRepo = _salesRepoOverride ?? SaleRepository();
  late final _buyersRepo = _buyersRepoOverride ?? BuyerRepository();
  late final _repairsRepo = _repairsRepoOverride ?? RepairRepository();

  ArchiveService({
    SaleRepository? salesRepo,
    BuyerRepository? buyersRepo,
    RepairRepository? repairsRepo,
  })  : _salesRepoOverride = salesRepo,
        _buyersRepoOverride = buyersRepo,
        _repairsRepoOverride = repairsRepo;

  Future<File> exportYear(int year) async {
    final sales = await _salesRepo.getSalesForYear(year);
    final repairs = await _repairsRepo.getRepairsForYear(year);
    final buyers = await _buyersRepo.getAllBuyers();

    final buyerAddresses = <String, List<Map<String, dynamic>>>{};
    for (final buyer in buyers) {
      final addresses = await _buyersRepo.getAllAddressesForBuyer(buyer.id);
      buyerAddresses[buyer.id] = addresses
          .map((a) => {'id': a.id, ...a.toFirestore()})
          .toList();
    }

    final archive = _toJsonSafe({
      'version': _kCurrentArchiveVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'year': year,
      'sales': sales
          .map((s) => {'id': s.id, ...s.toFirestore()})
          .toList(),
      'repairs': repairs
          .map((r) => {'id': r.id, ...r.toFirestore()})
          .toList(),
      'buyers': buyers
          .map((b) => {
                'id': b.id,
                ...b.toFirestore(),
                'addresses': buyerAddresses[b.id] ?? [],
              })
          .toList(),
    });

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/latitude_tracker_$year.json');
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
      final addresses = (buyerMap['addresses'] as List?)
              ?.cast<Map<String, dynamic>>()
              .where((a) => (a['id'] as String?) != null && (a['id'] as String).isNotEmpty)
              .map((a) => BuyerAddress.fromArchiveMap(buyer.id, a))
              .toList() ??
          [];
      final created =
          await _buyersRepo.createBuyerIfNotExists(buyer, addresses);
      if (created) { buyersImported++; } else { skipped++; }
    }

    for (final saleMap in sales) {
      final saleId = saleMap['id'] as String?;
      if (saleId == null || saleId.isEmpty) continue;
      final sale = Sale.fromArchiveMap(saleMap);
      final created = await _salesRepo.createSaleIfNotExists(sale);
      if (created) { salesImported++; } else { skipped++; }
    }

    for (final repairMap in repairs) {
      final repairId = repairMap['id'] as String?;
      if (repairId == null || repairId.isEmpty) continue;
      final repair = Repair.fromArchiveMap(repairMap);
      final created = await _repairsRepo.createRepairIfNotExists(repair);
      if (created) { repairsImported++; } else { skipped++; }
    }

    return ImportResult(
      salesImported: salesImported,
      buyersImported: buyersImported,
      repairsImported: repairsImported,
      skipped: skipped,
    );
  }

  // Firestore Timestamps are not JSON-serialisable — convert them to ISO strings.
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
    } catch (_) {
      return null;
    }
  }
}
