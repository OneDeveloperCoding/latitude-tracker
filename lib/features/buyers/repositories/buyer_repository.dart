import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../demo/demo_mode.dart';
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

  Future<List<Buyer>> getAllBuyers() {
    if (DemoMode.active.value) return DemoMode.buyerRepo.getAllBuyers();
    return _buyersRef
        .orderBy('name')
        .get()
        .then((snap) => snap.docs.map(Buyer.fromFirestore).toList());
  }

  Future<List<BuyerAddress>> getAllAddressesForBuyer(String buyerId) {
    if (DemoMode.active.value) {
      return DemoMode.buyerRepo.getAllAddressesForBuyer(buyerId);
    }
    return _addressesRef(buyerId)
        .get()
        .then((snap) => snap.docs.map(BuyerAddress.fromFirestore).toList());
  }

  Stream<List<Buyer>> watchBuyers() {
    if (DemoMode.active.value) return DemoMode.buyerRepo.watchBuyers();
    return _buyersRef
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(Buyer.fromFirestore).toList());
  }

  Future<Buyer?> getBuyer(String id) {
    if (DemoMode.active.value) return DemoMode.buyerRepo.getBuyer(id);
    return _buyersRef
        .doc(id)
        .get()
        .then((doc) => doc.exists ? Buyer.fromFirestore(doc) : null);
  }

  Future<void> createBuyer(Buyer buyer) {
    if (DemoMode.active.value) return DemoMode.buyerRepo.createBuyer(buyer);
    return _buyersRef.doc(buyer.id).set(buyer.toFirestore());
  }

  Future<void> updateBuyer(Buyer buyer) {
    if (DemoMode.active.value) return DemoMode.buyerRepo.updateBuyer(buyer);
    return _buyersRef.doc(buyer.id).update(buyer.toFirestore());
  }

  Future<void> deleteBuyer(String id) async {
    if (DemoMode.active.value) return DemoMode.buyerRepo.deleteBuyer(id);
    final addresses = await _addressesRef(id).get();
    final batch = _firestore.batch();
    for (final doc in addresses.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_buyersRef.doc(id));
    await batch.commit();
  }

  Stream<List<BuyerAddress>> watchAddresses(String buyerId) {
    if (DemoMode.active.value) {
      return DemoMode.buyerRepo.watchAddresses(buyerId);
    }
    return _addressesRef(buyerId)
        .orderBy('label')
        .snapshots()
        .map((snap) => snap.docs.map(BuyerAddress.fromFirestore).toList());
  }

  Future<void> createAddress(String buyerId, BuyerAddress address) async {
    if (DemoMode.active.value) {
      return DemoMode.buyerRepo.createAddress(buyerId, address);
    }
    final batch = _firestore.batch();
    if (address.isDefault) {
      await _clearDefaultAddress(buyerId, batch);
    }
    batch.set(_addressesRef(buyerId).doc(address.id), address.toFirestore());
    await batch.commit();
  }

  Future<void> updateAddress(String buyerId, BuyerAddress address) async {
    if (DemoMode.active.value) {
      return DemoMode.buyerRepo.updateAddress(buyerId, address);
    }
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

  Future<void> deleteAddress(String buyerId, String addressId) {
    if (DemoMode.active.value) {
      return DemoMode.buyerRepo.deleteAddress(buyerId, addressId);
    }
    return _addressesRef(buyerId).doc(addressId).delete();
  }

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
