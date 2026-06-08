import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'auth_revoked_exception.dart';
import 'error_reporter.dart';

abstract class BasePhotoService {
  final storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();

  String get userId =>
      _auth.currentUser?.uid ?? (throw const AuthRevokedException());

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

  // rootPathBuilder is called AFTER the auth guard so userId is never evaluated
  // on a signed-out session. Recursively deletes all files under the returned
  // path. Safe to call when the folder doesn't exist.
  Future<void> deleteAllInFolder(String Function() rootPathBuilder) async {
    if (_auth.currentUser == null) return;
    try {
      await _deleteFolder(rootPathBuilder());
    } catch (e, st) {
      if (e is AuthRevokedException) rethrow;
      // Folder may not exist — best-effort, but track unexpected errors.
      logError(e, st);
    }
  }

  Future<void> _deleteFolder(String path) async {
    final result = await storage.ref(path).listAll();
    // Run all deletes and sub-folder recursions in parallel. Each item is
    // wrapped in its own error handler so one failure never orphans the rest.
    await Future.wait([
      for (final item in result.items) _deleteItem(item),
      for (final prefix in result.prefixes) _deleteFolder(prefix.fullPath),
    ]);
  }

  Future<void> _deleteItem(Reference item) async {
    try {
      await item.delete();
    } catch (e, st) {
      // object-not-found is expected when the other device already deleted the
      // file — treat it as success. Log everything else.
      if (e is FirebaseException && e.code == 'object-not-found') return;
      logError(e, st);
    }
  }
}
