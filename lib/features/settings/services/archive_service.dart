import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../buyers/repositories/buyer_repository.dart';
import '../../repairs/repositories/repair_repository.dart';
import '../../sales/repositories/sale_repository.dart';

// Version 1.1 adds a `repairs` array. Version 1.2 adds `handDelivery` type.
const _kCurrentArchiveVersion = '1.2';
const _kSupportedArchiveVersions = {'1.0', '1.1', '1.2'};

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
  // late so Firebase isn't accessed until the first actual read/write call,
  // allowing the version check to throw before any Firebase interaction.
  late final _salesRepo = SaleRepository();
  late final _buyersRepo = BuyerRepository();
  late final _repairsRepo = RepairRepository();

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

    final firestore = FirebaseFirestore.instance;
    // TODO(safety): currentUser! will crash on a mid-flight auth revoke. Safe for
    // now because the router gates all repo access behind the auth stream, but
    // worth adding a null-guard if auth edge cases become a concern.
    final userId = FirebaseAuth.instance.currentUser!.uid;

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
      if (buyerId == null) continue;

      final buyerRef = firestore
          .collection('users')
          .doc(userId)
          .collection('buyers')
          .doc(buyerId);

      final existing = await buyerRef.get();
      if (existing.exists) {
        skipped++;
        continue;
      }

      final addresses =
          (buyerMap['addresses'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      final batch = firestore.batch();
      batch.set(buyerRef, toFirestoreMap(Map.from(buyerMap)
        ..remove('id')
        ..remove('addresses')));

      for (final addrMap in addresses) {
        final addrId = addrMap['id'] as String?;
        if (addrId == null) continue;
        final addrRef = buyerRef.collection('addresses').doc(addrId);
        batch.set(addrRef,
            toFirestoreMap(Map<String, dynamic>.from(addrMap)..remove('id')));
      }

      await batch.commit();
      buyersImported++;
    }

    for (final saleMap in sales) {
      final saleId = saleMap['id'] as String?;
      if (saleId == null) continue;

      final saleRef = firestore
          .collection('users')
          .doc(userId)
          .collection('sales')
          .doc(saleId);

      final existing = await saleRef.get();
      if (existing.exists) {
        skipped++;
        continue;
      }

      await saleRef.set(toFirestoreMap(Map.from(saleMap)..remove('id')));
      salesImported++;
    }

    for (final repairMap in repairs) {
      final repairId = repairMap['id'] as String?;
      if (repairId == null) continue;

      final repairRef = firestore
          .collection('users')
          .doc(userId)
          .collection('repairs')
          .doc(repairId);

      final existing = await repairRef.get();
      if (existing.exists) {
        skipped++;
        continue;
      }

      await repairRef.set(toFirestoreMap(Map.from(repairMap)..remove('id')));
      repairsImported++;
    }

    return ImportResult(
      salesImported: salesImported,
      buyersImported: buyersImported,
      repairsImported: repairsImported,
      skipped: skipped,
    );
  }

  // Converts ISO date strings back to Firestore Timestamps for known date fields.
  // All other values pass through unchanged.
  @visibleForTesting
  static Map<String, dynamic> toFirestoreMap(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is String &&
          (key == 'createdAt' || key == 'scheduledDate')) {
        final dt = DateTime.tryParse(value);
        if (dt != null) return MapEntry(key, Timestamp.fromDate(dt));
      }
      if (value is Map) {
        return MapEntry(
            key, toFirestoreMap(Map<String, dynamic>.from(value)));
      }
      if (value is List) {
        return MapEntry(key, value.map((v) {
          if (v is Map) return toFirestoreMap(Map<String, dynamic>.from(v));
          return v;
        }).toList());
      }
      return MapEntry(key, value);
    });
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
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
      return null;
    }
  }
}
