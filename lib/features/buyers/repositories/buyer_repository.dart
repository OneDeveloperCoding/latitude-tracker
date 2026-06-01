import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/buyer.dart';
import '../models/buyer_address.dart';

class BuyerRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _buyersRef =>
      _firestore.collection('users').doc(_userId).collection('buyers');

  CollectionReference<Map<String, dynamic>> _addressesRef(String buyerId) =>
      _buyersRef.doc(buyerId).collection('addresses');

  Future<List<Buyer>> getAllBuyers() async {
    final snap = await _buyersRef.orderBy('name').get();
    return snap.docs.map(Buyer.fromFirestore).toList();
  }

  Future<List<BuyerAddress>> getAllAddressesForBuyer(String buyerId) async {
    final snap = await _addressesRef(buyerId).get();
    return snap.docs.map(BuyerAddress.fromFirestore).toList();
  }

  Stream<List<Buyer>> watchBuyers() => _buyersRef
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map(Buyer.fromFirestore).toList());

  Future<Buyer?> getBuyer(String id) async {
    final doc = await _buyersRef.doc(id).get();
    return doc.exists ? Buyer.fromFirestore(doc) : null;
  }

  Future<void> createBuyer(Buyer buyer) =>
      _buyersRef.doc(buyer.id).set(buyer.toFirestore());

  Future<void> updateBuyer(Buyer buyer) =>
      _buyersRef.doc(buyer.id).update(buyer.toFirestore());

  Future<void> deleteBuyer(String id) async {
    final addresses = await _addressesRef(id).get();
    final batch = _firestore.batch();
    for (final doc in addresses.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_buyersRef.doc(id));
    await batch.commit();
  }

  Stream<List<BuyerAddress>> watchAddresses(String buyerId) =>
      _addressesRef(buyerId)
          .orderBy('label')
          .snapshots()
          .map((snap) => snap.docs.map(BuyerAddress.fromFirestore).toList());

  Future<void> createAddress(String buyerId, BuyerAddress address) async {
    final batch = _firestore.batch();
    if (address.isDefault) {
      await _clearDefaultAddress(buyerId, batch);
    }
    batch.set(_addressesRef(buyerId).doc(address.id), address.toFirestore());
    await batch.commit();
  }

  Future<void> updateAddress(String buyerId, BuyerAddress address) async {
    final batch = _firestore.batch();
    if (address.isDefault) {
      await _clearDefaultAddress(buyerId, batch, excludeId: address.id);
    }
    batch.update(
      _addressesRef(buyerId).doc(address.id),
      address.toFirestore(),
    );
    await batch.commit();
  }

  Future<void> deleteAddress(String buyerId, String addressId) =>
      _addressesRef(buyerId).doc(addressId).delete();

  Future<void> _clearDefaultAddress(
    String buyerId,
    WriteBatch batch, {
    String? excludeId,
  }) async {
    final existing = await _addressesRef(buyerId)
        .where('isDefault', isEqualTo: true)
        .get();
    for (final doc in existing.docs) {
      if (doc.id != excludeId) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }
  }
}
