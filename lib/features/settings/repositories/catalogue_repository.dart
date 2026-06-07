import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/auth_revoked_exception.dart';
import '../../demo/demo_mode.dart';

abstract class CatalogueRepository {
  factory CatalogueRepository() => DemoMode.active.value
      ? DemoMode.catalogueRepo
      : _FirestoreCatalogueRepository();

  Future<List<String>> fetchHiddenCategories();
  Future<void> saveHiddenCategories(List<String> hidden);
  Future<void> addHiddenCategory(String name);
  Future<void> removeHiddenCategory(String name);
}

class _FirestoreCatalogueRepository implements CatalogueRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _userId =>
      _auth.currentUser?.uid ?? (throw const AuthRevokedException());

  DocumentReference<Map<String, dynamic>> get _docRef => _firestore
      .collection('users')
      .doc(_userId)
      .collection('settings')
      .doc('catalogue');

  @override
  Future<List<String>> fetchHiddenCategories() async {
    final snap = await _docRef.get();
    if (!snap.exists) return [];
    return (snap.data()?['hiddenCategories'] as List<dynamic>?)
            ?.cast<String>() ??
        [];
  }

  @override
  Future<void> saveHiddenCategories(List<String> hidden) =>
      _docRef.set({'hiddenCategories': hidden.toSet().toList()}, SetOptions(merge: true));

  @override
  Future<void> addHiddenCategory(String name) =>
      _docRef.set(
        {'hiddenCategories': FieldValue.arrayUnion([name])},
        SetOptions(merge: true),
      );

  @override
  Future<void> removeHiddenCategory(String name) =>
      _docRef.set(
        {'hiddenCategories': FieldValue.arrayRemove([name])},
        SetOptions(merge: true),
      );
}

class InMemoryCatalogueRepository implements CatalogueRepository {
  List<String> _hidden = [];

  @override
  Future<List<String>> fetchHiddenCategories() async =>
      List.unmodifiable(_hidden);

  @override
  Future<void> saveHiddenCategories(List<String> hidden) async =>
      _hidden = hidden.toSet().toList();

  @override
  Future<void> addHiddenCategory(String name) async {
    if (!_hidden.contains(name)) _hidden = [..._hidden, name];
  }

  @override
  Future<void> removeHiddenCategory(String name) async =>
      _hidden = _hidden.where((c) => c != name).toList();

  void clear() => _hidden = [];
}
