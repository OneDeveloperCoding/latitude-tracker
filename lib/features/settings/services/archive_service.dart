import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

import '../../buyers/repositories/buyer_repository.dart';
import '../../sales/repositories/sale_repository.dart';

class ImportResult {
  final int salesImported;
  final int buyersImported;
  final int skipped;

  const ImportResult({
    required this.salesImported,
    required this.buyersImported,
    required this.skipped,
  });
}

class ArchiveService {
  final _salesRepo = SaleRepository();
  final _buyersRepo = BuyerRepository();

  Future<File> exportYear(int year) async {
    final sales = await _salesRepo.getSalesForYear(year);
    final buyers = await _buyersRepo.getAllBuyers();

    final buyerAddresses = <String, List<Map<String, dynamic>>>{};
    for (final buyer in buyers) {
      final addresses = await _buyersRepo.getAllAddressesForBuyer(buyer.id);
      buyerAddresses[buyer.id] = addresses
          .map((a) => {'id': a.id, ...a.toFirestore()})
          .toList();
    }

    final archive = _toJsonSafe({
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'year': year,
      'sales': sales
          .map((s) => {'id': s.id, ...s.toFirestore()})
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
  Future<ImportResult> importArchive(Map<String, dynamic> archive) async {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final sales =
        (archive['sales'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final buyers =
        (archive['buyers'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    var salesImported = 0;
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
      batch.set(buyerRef, _toFirestoreMap(Map.from(buyerMap)
        ..remove('id')
        ..remove('addresses')));

      for (final addrMap in addresses) {
        final addrId = addrMap['id'] as String?;
        if (addrId == null) continue;
        final addrRef = buyerRef.collection('addresses').doc(addrId);
        batch.set(addrRef,
            Map<String, dynamic>.from(addrMap)..remove('id'));
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

      await saleRef.set(_toFirestoreMap(Map.from(saleMap)..remove('id')));
      salesImported++;
    }

    return ImportResult(
      salesImported: salesImported,
      buyersImported: buyersImported,
      skipped: skipped,
    );
  }

  // Converts ISO date strings back to Firestore Timestamps for known date fields.
  // All other values pass through unchanged.
  static Map<String, dynamic> _toFirestoreMap(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is String &&
          (key == 'createdAt' || key == 'scheduledDate')) {
        final dt = DateTime.tryParse(value);
        if (dt != null) return MapEntry(key, Timestamp.fromDate(dt));
      }
      if (value is Map) {
        return MapEntry(
            key, _toFirestoreMap(Map<String, dynamic>.from(value)));
      }
      if (value is List) {
        return MapEntry(key, value.map((v) {
          if (v is Map) return _toFirestoreMap(Map<String, dynamic>.from(v));
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
    } catch (_) {
      return null;
    }
  }
}
