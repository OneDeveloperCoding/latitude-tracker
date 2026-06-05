import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/auth_revoked_exception.dart';
import '../../demo/demo_mode.dart';
import '../models/buyer.dart';
import '../models/buyer_address.dart';

abstract class BuyerRepository {
  factory BuyerRepository() =>
      DemoMode.active.value ? DemoMode.buyerRepo : _FirestoreBuyerRepository();

  Stream<List<Buyer>> watchBuyers();
  Stream<List<BuyerAddress>> watchAddresses(String buyerId);
  Stream<List<BuyerAddress>> watchAllAddresses();
  Future<List<Buyer>> getAllBuyers();
  Future<Buyer?> getBuyer(String id);
  Future<List<BuyerAddress>> getAllAddressesForBuyer(String buyerId);
  Future<void> createBuyer(Buyer buyer);
  Future<void> updateBuyer(Buyer buyer);
  Future<void> deleteBuyer(String id);
  Future<void> deleteAllBuyers();
  Future<void> createAddress(String buyerId, BuyerAddress address);
  Future<void> updateAddress(String buyerId, BuyerAddress address);
  Future<void> deleteAddress(String buyerId, String addressId);
}

class _FirestoreBuyerRepository implements BuyerRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _userId =>
      _auth.currentUser?.uid ?? (throw const AuthRevokedException());

  CollectionReference<Map<String, dynamic>> get _buyersRef =>
      _firestore.collection('users').doc(_userId).collection('buyers');

  CollectionReference<Map<String, dynamic>> _addressesRef(String buyerId) =>
      _buyersRef.doc(buyerId).collection('addresses');

  @override
  Future<List<Buyer>> getAllBuyers() => _buyersRef
      .orderBy('name')
      .get()
      .then((snap) => snap.docs.map(Buyer.fromFirestore).toList());

  @override
  Future<List<BuyerAddress>> getAllAddressesForBuyer(String buyerId) =>
      _addressesRef(buyerId)
          .get()
          .then((snap) => snap.docs.map(BuyerAddress.fromFirestore).toList());

  @override
  Stream<List<Buyer>> watchBuyers() => _buyersRef
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map(Buyer.fromFirestore).toList());

  @override
  Future<Buyer?> getBuyer(String id) => _buyersRef
      .doc(id)
      .get()
      .then((doc) => doc.exists ? Buyer.fromFirestore(doc) : null);

  @override
  Future<void> createBuyer(Buyer buyer) =>
      _buyersRef.doc(buyer.id).set(buyer.toFirestore());

  @override
  Future<void> updateBuyer(Buyer buyer) =>
      _buyersRef.doc(buyer.id).update(buyer.toFirestore());

  @override
  Future<void> deleteBuyer(String id) async {
    final addresses = await _addressesRef(id).get();
    final batch = _firestore.batch();
    for (final doc in addresses.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_buyersRef.doc(id));
    await batch.commit();
  }

  @override
  Stream<List<BuyerAddress>> watchAddresses(String buyerId) =>
      _addressesRef(buyerId)
          .orderBy('label')
          .snapshots()
          .map((snap) => snap.docs.map(BuyerAddress.fromFirestore).toList());

  @override
  Stream<List<BuyerAddress>> watchAllAddresses() =>
      _firestore
          .collectionGroup('addresses')
          .snapshots()
          .map((snap) => snap.docs.map(BuyerAddress.fromFirestore).toList());

  @override
  Future<void> deleteAllBuyers() async {
    final buyers = await getAllBuyers();
    for (final buyer in buyers) {
      await deleteBuyer(buyer.id);
    }
  }

  @override
  Future<void> createAddress(String buyerId, BuyerAddress address) async {
    final batch = _firestore.batch();
    if (address.isDefault) {
      await _clearDefaultAddress(buyerId, batch);
    }
    batch.set(_addressesRef(buyerId).doc(address.id), address.toFirestore());
    await batch.commit();
  }

  @override
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

  @override
  Future<void> deleteAddress(String buyerId, String addressId) =>
      _addressesRef(buyerId).doc(addressId).delete();

  Future<void> _clearDefaultAddress(
    String buyerId,
    WriteBatch batch, {
    String? excludeId,
  }) async {
    final existing =
        await _addressesRef(buyerId).where('isDefault', isEqualTo: true).get();
    for (final doc in existing.docs) {
      if (doc.id != excludeId) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }
  }
}
