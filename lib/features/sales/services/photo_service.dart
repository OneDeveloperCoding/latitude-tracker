import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/id_gen.dart';
import '../../../core/services/base_photo_service.dart';

class PhotoService extends BasePhotoService {
  Reference _photoRef(String saleId, String itemId, String photoId) =>
      storage.ref(
          'users/$userId/sales/$saleId/items/$itemId/photos/$photoId.jpg');

  Future<String?> pickAndUpload({
    required String saleId,
    required String itemId,
    required ImageSource source,
  }) =>
      uploadImage(_photoRef(saleId, itemId, newId()), source);

  Future<void> deleteAllPhotos(String saleId) =>
      deleteAllInFolder(() => 'users/$userId/sales/$saleId');
}
