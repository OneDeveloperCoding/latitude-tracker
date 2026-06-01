import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../demo/demo_mode.dart';
import '../models/sale.dart';
import '../services/photo_service.dart';

class SaleRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _salesRef =>
      _firestore.collection('users').doc(_userId).collection('sales');

  Stream<List<Sale>> watchSales() {
    if (DemoMode.active.value) return DemoMode.saleRepo.watchSales();
    return _salesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Sale.fromFirestore).toList());
  }

  Stream<Sale?> watchSale(String id) {
    if (DemoMode.active.value) return DemoMode.saleRepo.watchSale(id);
    return _salesRef
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Sale.fromFirestore(doc) : null);
  }

  Future<void> createSale(Sale sale) {
    if (DemoMode.active.value) return DemoMode.saleRepo.createSale(sale);
    return _salesRef.doc(sale.id).set(sale.toFirestore());
  }

  Future<void> updateSale(Sale sale) {
    if (DemoMode.active.value) return DemoMode.saleRepo.updateSale(sale);
    return _salesRef.doc(sale.id).update(sale.toFirestore());
  }

  Future<List<Sale>> getSalesForYear(int year) {
    if (DemoMode.active.value) return DemoMode.saleRepo.getSalesForYear(year);
    return _salesRef
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(year)))
        .where('createdAt',
            isLessThan: Timestamp.fromDate(DateTime(year + 1)))
        .get()
        .then((snap) => snap.docs.map(Sale.fromFirestore).toList());
  }

  // By default keeps photos in Storage so archive JSON URLs stay valid.
  // Pass deletePhotos: true for a full wipe (e.g. reset).
  Future<void> deleteAllSalesForYear(int year,
      {bool deletePhotos = false}) async {
    if (DemoMode.active.value) {
      return DemoMode.saleRepo.deleteAllSalesForYear(year);
    }
    final sales = await getSalesForYear(year);
    if (sales.isEmpty) return;
    if (deletePhotos) {
      for (final sale in sales) {
        await PhotoService().deleteAllPhotos(sale.id);
      }
    }
    final batch = _firestore.batch();
    for (final sale in sales) {
      batch.delete(_salesRef.doc(sale.id));
    }
    await batch.commit();
  }

  Stream<List<Sale>> watchSalesForBuyer(String buyerId) {
    if (DemoMode.active.value) {
      return DemoMode.saleRepo.watchSalesForBuyer(buyerId);
    }
    return _salesRef
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .map((snap) => snap.docs.map(Sale.fromFirestore).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<List<Sale>> getSalesForBuyer(String buyerId) {
    if (DemoMode.active.value) {
      return DemoMode.saleRepo.getSalesForBuyer(buyerId);
    }
    return _salesRef
        .where('buyerId', isEqualTo: buyerId)
        .get()
        .then((snap) => snap.docs.map(Sale.fromFirestore).toList());
  }

  Future<void> deleteSale(String id) async {
    if (DemoMode.active.value) return DemoMode.saleRepo.deleteSale(id);
    await PhotoService().deleteAllPhotos(id);
    await _salesRef.doc(id).delete();
  }
}
