import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'auth_revoked_exception.dart';
import 'error_reporter.dart';

abstract class BasePhotoService {
  final storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  String get userId =>
      _auth.currentUser?.uid ?? (throw const AuthRevokedException());

  String get newPhotoId => _uuid.v4();

  Future<String?> uploadImage(Reference ref, ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> deletePhoto(String photoUrl) async {
    if (photoUrl.startsWith('demo://')) return;
    try {
      await storage.refFromURL(photoUrl).delete();
    } catch (e, st) {
      // Photo may already be deleted — best-effort, but track unexpected errors.
      logError(e, st);
    }
  }

  Future<void> deleteAllInFolder(String rootPath) async {
    if (_auth.currentUser == null) return;
    try {
      await _deleteFolder(rootPath);
    } catch (e, st) {
      if (e is AuthRevokedException) rethrow;
      // Folder may not exist — best-effort, but track unexpected errors.
      logError(e, st);
    }
  }

  Future<void> _deleteFolder(String path) async {
    final result = await storage.ref(path).listAll();
    for (final item in result.items) {
      await item.delete();
    }
    for (final prefix in result.prefixes) {
      await _deleteFolder(prefix.fullPath);
    }
  }
}
