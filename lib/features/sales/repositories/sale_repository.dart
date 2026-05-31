import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/sale.dart';

class SaleRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _salesRef =>
      _firestore.collection('users').doc(_userId).collection('sales');

  Stream<List<Sale>> watchSales() => _salesRef
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Sale.fromFirestore).toList());

  Stream<Sale?> watchSale(String id) => _salesRef
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? Sale.fromFirestore(doc) : null);

  Future<void> createSale(Sale sale) =>
      _salesRef.doc(sale.id).set(sale.toFirestore());

  Future<void> updateSale(Sale sale) =>
      _salesRef.doc(sale.id).update(sale.toFirestore());

  Future<void> deleteSale(String id) => _salesRef.doc(id).delete();
}
