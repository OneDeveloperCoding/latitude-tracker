import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class PhotoService {
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  // TODO(safety): currentUser! will crash on a mid-flight auth revoke. Safe for
  // now because the router gates all repo access behind the auth stream, but
  // worth adding a null-guard if auth edge cases become a concern.
  String get _userId => _auth.currentUser!.uid;

  Reference _photoRef(String saleId, String itemId, String photoId) =>
      _storage.ref(
          'users/$_userId/sales/$saleId/items/$itemId/photos/$photoId.jpg');

  Future<String?> pickAndUpload({
    required String saleId,
    required String itemId,
    required ImageSource source,
  }) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final photoId = _uuid.v4();
    final ref = _photoRef(saleId, itemId, photoId);

    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  Future<void> deletePhoto(String saleId, String photoUrl) async {
    if (photoUrl.startsWith('demo://')) return;
    try {
      await _storage.refFromURL(photoUrl).delete();
    } catch (e, st) {
      // Photo may already be deleted — best-effort, but track unexpected errors.
      FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
    }
  }

  // Recursively deletes all files under the sale's Storage folder,
  // including all item subfolders. Safe to call when the folder doesn't exist.
  Future<void> deleteAllPhotos(String saleId) async {
    if (_auth.currentUser == null) return;
    try {
      await _deleteFolder('users/$_userId/sales/$saleId');
    } catch (e, st) {
      // Folder may not exist — best-effort, but track unexpected errors.
      FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
    }
  }

  Future<void> _deleteFolder(String path) async {
    final result = await _storage.ref(path).listAll();
    for (final item in result.items) {
      await item.delete();
    }
    for (final prefix in result.prefixes) {
      await _deleteFolder(prefix.fullPath);
    }
  }
}
