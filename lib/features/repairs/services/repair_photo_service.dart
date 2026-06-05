import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_revoked_exception.dart';
import '../../../core/services/error_reporter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class RepairPhotoService {
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  String get _userId =>
      _auth.currentUser?.uid ?? (throw const AuthRevokedException());

  Reference _photoRef(String repairId, String photoId) =>
      _storage.ref('users/$_userId/repairs/$repairId/photos/$photoId.jpg');

  Future<String?> pickAndUpload({
    required String repairId,
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
    final ref = _photoRef(repairId, photoId);

    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  Future<void> deletePhoto(String photoUrl) async {
    if (photoUrl.startsWith('demo://')) return;
    try {
      await _storage.refFromURL(photoUrl).delete();
    } catch (e, st) {
      // Photo may already be deleted — best-effort, but track unexpected errors.
      logError(e, st);
    }
  }

  Future<void> deleteAllPhotos(String repairId) async {
    if (_auth.currentUser == null) return;
    try {
      await _deleteFolder('users/$_userId/repairs/$repairId');
    } catch (e, st) {
      if (e is AuthRevokedException) rethrow;
      // Folder may not exist — best-effort, but track unexpected errors.
      logError(e, st);
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
