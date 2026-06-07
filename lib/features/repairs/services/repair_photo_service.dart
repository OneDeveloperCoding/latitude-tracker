import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/id_gen.dart';
import '../../../core/services/base_photo_service.dart';

class RepairPhotoService extends BasePhotoService {
  Reference _photoRef(String repairId, String photoId) =>
      storage.ref('users/$userId/repairs/$repairId/photos/$photoId.jpg');

  Future<String?> pickAndUpload({
    required String repairId,
    required ImageSource source,
  }) =>
      uploadImage(_photoRef(repairId, newId()), source);

  Future<void> deleteAllPhotos(String repairId) =>
      deleteAllInFolder(() => 'users/$userId/repairs/$repairId');
}
