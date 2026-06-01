import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class PhotoService {
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  String get _userId => _auth.currentUser!.uid;

  Reference _photoRef(String saleId, String photoId) =>
      _storage.ref('users/$_userId/sales/$saleId/photos/$photoId.jpg');

  Future<String?> pickAndUpload({
    required String saleId,
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
    final ref = _photoRef(saleId, photoId);

    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  Future<void> deletePhoto(String saleId, String photoUrl) async {
    try {
      await _storage.refFromURL(photoUrl).delete();
    } catch (_) {
      // Photo may already be deleted — ignore
    }
  }

  Future<void> deleteAllPhotos(String saleId) async {
    try {
      final listResult =
          await _storage.ref('users/$_userId/sales/$saleId/photos').listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (_) {
      // Folder may not exist — ignore
    }
  }
}
