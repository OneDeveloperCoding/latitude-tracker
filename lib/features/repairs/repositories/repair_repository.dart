import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../demo/demo_mode.dart';
import '../models/repair.dart';
import '../services/repair_photo_service.dart';

abstract class RepairRepository {
  factory RepairRepository() =>
      DemoMode.active.value ? DemoMode.repairRepo : _FirestoreRepairRepository();

  Stream<List<Repair>> watchRepairs();
  Stream<Repair?> watchRepair(String id);
  Stream<List<Repair>> watchRepairsForSale(String saleId);
  Future<void> createRepair(Repair repair);
  Future<void> updateRepair(Repair repair);
  Future<void> deleteRepair(String id);
  Future<List<Repair>> getRepairsForYear(int year);
  Future<void> deleteAllRepairsForYear(int year, {bool deletePhotos});
  Future<void> deleteAllRepairs({bool deletePhotos});
}

class _FirestoreRepairRepository implements RepairRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _repairsRef =>
      _firestore.collection('users').doc(_userId).collection('repairs');

  @override
  Stream<List<Repair>> watchRepairs() => _repairsRef
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Repair.fromFirestore).toList());

  @override
  Stream<Repair?> watchRepair(String id) => _repairsRef
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? Repair.fromFirestore(doc) : null);

  @override
  Stream<List<Repair>> watchRepairsForSale(String saleId) => _repairsRef
      .where('linkedSaleId', isEqualTo: saleId)
      .snapshots()
      .map((snap) => snap.docs.map(Repair.fromFirestore).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  @override
  Future<void> createRepair(Repair repair) =>
      _repairsRef.doc(repair.id).set(repair.toFirestore());

  @override
  Future<void> updateRepair(Repair repair) =>
      _repairsRef.doc(repair.id).update(repair.toFirestore());

  @override
  Future<void> deleteRepair(String id) async {
    await RepairPhotoService().deleteAllPhotos(id);
    await _repairsRef.doc(id).delete();
  }

  @override
  Future<List<Repair>> getRepairsForYear(int year) => _repairsRef
      .where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(year)))
      .where('createdAt', isLessThan: Timestamp.fromDate(DateTime(year + 1)))
      .get()
      .then((snap) => snap.docs.map(Repair.fromFirestore).toList());

  @override
  Future<void> deleteAllRepairsForYear(int year,
      {bool deletePhotos = false}) async {
    final repairs = await getRepairsForYear(year);
    if (repairs.isEmpty) return;
    if (deletePhotos) {
      for (final repair in repairs) {
        await RepairPhotoService().deleteAllPhotos(repair.id);
      }
    }
    final batch = _firestore.batch();
    for (final repair in repairs) {
      batch.delete(_repairsRef.doc(repair.id));
    }
    await batch.commit();
  }

  @override
  Future<void> deleteAllRepairs({bool deletePhotos = false}) async {
    final docs = await _repairsRef.get().then((s) => s.docs);
    if (docs.isEmpty) return;
    if (deletePhotos) {
      for (final doc in docs) {
        await RepairPhotoService().deleteAllPhotos(doc.id);
      }
    }
    final batch = _firestore.batch();
    for (final doc in docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
