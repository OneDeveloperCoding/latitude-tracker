import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:latitude_tracker/core/services/auth_revoked_exception.dart';
import 'package:latitude_tracker/core/services/firestore_batch_utils.dart';
import 'package:latitude_tracker/features/demo/demo_mode.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/repairs/services/repair_photo_service.dart';

abstract class RepairRepository {
  factory RepairRepository() =>
      DemoMode.active.value ? DemoMode.repairRepo : _FirestoreRepairRepository();

  Stream<List<Repair>> watchRepairs();
  Stream<Repair?> watchRepair(String id);
  Stream<List<Repair>> watchRepairsForSale(String saleId);
  Future<void> createRepair(Repair repair);
  Future<bool> createRepairIfNotExists(Repair repair);
  Future<void> updateRepair(Repair repair);
  Future<void> deleteRepair(String id);
  Future<List<Repair>> getRepairsForYear(int year);
  Future<void> deleteAllRepairsForYear(int year, {bool deletePhotos});
  Future<void> deleteAllRepairs({bool deletePhotos});
  Future<void> renameCategory(String oldName, String newName);
}

class _FirestoreRepairRepository implements RepairRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId =>
      _auth.currentUser?.uid ?? (throw const AuthRevokedException());

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
  Future<bool> createRepairIfNotExists(Repair repair) =>
      createDocIfNotExists(_repairsRef.doc(repair.id), repair.toFirestore());

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

  // By default keeps photos in Storage so archive JSON URLs stay valid.
  // Pass deletePhotos: true for a full wipe (e.g. reset).
  @override
  Future<void> deleteAllRepairsForYear(int year,
      {bool deletePhotos = false}) async {
    final repairs = await getRepairsForYear(year);
    if (repairs.isEmpty) return;
    if (deletePhotos) {
      // Photos before Firestore: if photo deletion fails, docs remain intact
      // and the caller can retry without orphaning anything.
      for (final repair in repairs) {
        await RepairPhotoService().deleteAllPhotos(repair.id);
      }
    }
    await commitInBatches<DocumentReference>(
      _firestore,
      repairs.map((r) => _repairsRef.doc(r.id)).toList(),
      (batch, ref) => batch.delete(ref),
    );
  }

  @override
  Future<void> deleteAllRepairs({bool deletePhotos = false}) async {
    final docs = await _repairsRef.get().then((s) => s.docs);
    if (docs.isEmpty) return;
    if (deletePhotos) {
      // Photos before Firestore: if photo deletion fails, docs remain intact
      // and the caller can retry without orphaning anything.
      for (final doc in docs) {
        await RepairPhotoService().deleteAllPhotos(doc.id);
      }
    }
    await commitInBatches<DocumentReference>(
      _firestore,
      docs.map((d) => d.reference).toList(),
      (batch, ref) => batch.delete(ref),
    );
  }

  @override
  Future<void> renameCategory(String oldName, String newName) async {
    final snap = await _repairsRef
        .where('itemCategory', isEqualTo: oldName)
        .get();
    if (snap.docs.isEmpty) return;

    await commitInBatches(
      _firestore,
      snap.docs,
      (batch, doc) => batch.update(doc.reference, {'itemCategory': newName}),
    );
  }
}
