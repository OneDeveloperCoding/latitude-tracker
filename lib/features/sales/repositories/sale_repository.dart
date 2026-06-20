import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:latitude_tracker/core/services/auth_revoked_exception.dart';
import 'package:latitude_tracker/core/services/firestore_batch_utils.dart';
import 'package:latitude_tracker/features/demo/demo_mode.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/services/photo_service.dart';

abstract class SaleRepository {
  factory SaleRepository() =>
      DemoMode.active.value ? DemoMode.saleRepo : _FirestoreSaleRepository();

  Stream<List<Sale>> watchSales();
  Stream<Sale?> watchSale(String id);
  Stream<List<Sale>> watchSalesForBuyer(String buyerId);
  Future<void> createSale(Sale sale);
  Future<bool> createSaleIfNotExists(Sale sale);
  Future<void> updateSale(Sale sale);
  // Writes only the specified dot-notation fields, preventing stale-snapshot
  // overwrites when only payment or shipment state needs to change.
  Future<void> patchSale(String id, Map<String, dynamic> fields);
  Future<void> deleteSale(String id);
  Future<List<Sale>> getSalesForYear(int year);
  Future<void> deleteAllSalesForYear(int year, {bool deletePhotos});
  Future<void> deleteAllSales({bool deletePhotos});
  Future<List<Sale>> getSalesForBuyer(String buyerId);
  Future<void> renameCategory(String oldName, String newName);
}

class _FirestoreSaleRepository implements SaleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId =>
      _auth.currentUser?.uid ?? (throw const AuthRevokedException());

  CollectionReference<Map<String, dynamic>> get _salesRef =>
      _firestore.collection('users').doc(_userId).collection('sales');

  @override
  Stream<List<Sale>> watchSales() => _salesRef
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Sale.fromFirestore).toList());

  @override
  Stream<Sale?> watchSale(String id) => _salesRef
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? Sale.fromFirestore(doc) : null);

  @override
  Future<void> createSale(Sale sale) =>
      _salesRef.doc(sale.id).set(sale.toFirestore());

  @override
  Future<bool> createSaleIfNotExists(Sale sale) =>
      createDocIfNotExists(_salesRef.doc(sale.id), sale.toFirestore());

  @override
  Future<void> updateSale(Sale sale) =>
      _salesRef.doc(sale.id).update(sale.toFirestore());

  @override
  Future<void> patchSale(String id, Map<String, dynamic> fields) =>
      _salesRef.doc(id).update(fields);

  @override
  Future<List<Sale>> getSalesForYear(int year) => _salesRef
      .where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(year)),
      )
      .where('createdAt', isLessThan: Timestamp.fromDate(DateTime(year + 1)))
      .get()
      .then((snap) => snap.docs.map(Sale.fromFirestore).toList());

  // By default keeps photos in Storage so archive JSON URLs stay valid.
  // Pass deletePhotos: true for a full wipe (e.g. reset).
  @override
  Future<void> deleteAllSalesForYear(
    int year, {
    bool deletePhotos = false,
  }) async {
    final sales = await getSalesForYear(year);
    if (sales.isEmpty) return;
    if (deletePhotos) {
      // Photos before Firestore: if photo deletion fails, docs remain intact
      // and the caller can retry without orphaning anything.
      for (final sale in sales) {
        await PhotoService().deleteAllPhotos(sale.id);
      }
    }
    await commitInBatches<DocumentReference>(
      _firestore,
      sales.map((s) => _salesRef.doc(s.id)).toList(),
      (batch, ref) => batch.delete(ref),
    );
  }

  @override
  Future<void> deleteAllSales({bool deletePhotos = false}) async {
    final docs = await _salesRef.get().then((s) => s.docs);
    if (docs.isEmpty) return;
    if (deletePhotos) {
      // Photos before Firestore: if photo deletion fails, docs remain intact
      // and the caller can retry without orphaning anything.
      for (final doc in docs) {
        await PhotoService().deleteAllPhotos(doc.id);
      }
    }
    await commitInBatches<DocumentReference>(
      _firestore,
      docs.map((d) => d.reference).toList(),
      (batch, ref) => batch.delete(ref),
    );
  }

  @override
  Stream<List<Sale>> watchSalesForBuyer(String buyerId) => _salesRef
      .where('buyerId', isEqualTo: buyerId)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map(Sale.fromFirestore).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  @override
  Future<List<Sale>> getSalesForBuyer(String buyerId) => _salesRef
      .where('buyerId', isEqualTo: buyerId)
      .get()
      .then((snap) => snap.docs.map(Sale.fromFirestore).toList());

  @override
  Future<void> deleteSale(String id) async {
    await PhotoService().deleteAllPhotos(id);
    await _salesRef.doc(id).delete();
  }

  @override
  Future<void> renameCategory(String oldName, String newName) async {
    final snap = await _salesRef.get();
    final toUpdate = snap.docs.where((doc) {
      final items = doc.data()['items'] as List<dynamic>? ?? [];
      return items.any(
        (item) => (item as Map<String, dynamic>)['category'] == oldName,
      );
    }).toList();
    if (toUpdate.isEmpty) return;

    await commitInBatches(
      _firestore,
      toUpdate,
      (batch, doc) {
        final items = (doc.data()['items'] as List<dynamic>).map((raw) {
          final item = Map<String, dynamic>.from(raw as Map);
          if (item['category'] == oldName) item['category'] = newName;
          return item;
        }).toList();
        batch.update(doc.reference, {'items': items});
      },
    );
  }
}
