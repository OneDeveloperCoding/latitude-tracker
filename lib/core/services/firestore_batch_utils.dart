import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore's hard limit is 500 operations per WriteBatch. 499 leaves one slot
// of headroom regardless of SDK version or batch-size counting edge cases.
const _kBatchSize = 499;

/// Writes [data] to [ref] only if the document does not yet exist.
/// Returns true if the document was created, false if it already existed.
Future<bool> createDocIfNotExists(
  DocumentReference<Map<String, dynamic>> ref,
  Map<String, dynamic> data,
) async {
  if ((await ref.get()).exists) return false;
  await ref.set(data);
  return true;
}

/// Splits [items] into chunks of up to [_kBatchSize] and commits one
/// [WriteBatch] per chunk. [addToBatch] is called for every item to stage the
/// desired operation (delete, update, set, …) before each commit.
Future<void> commitInBatches<T>(
  FirebaseFirestore firestore,
  List<T> items,
  void Function(WriteBatch batch, T item) addToBatch,
) async {
  for (var i = 0; i < items.length; i += _kBatchSize) {
    final chunk = items.sublist(i, math.min(i + _kBatchSize, items.length));
    final batch = firestore.batch();
    for (final item in chunk) {
      addToBatch(batch, item);
    }
    await batch.commit();
  }
}
