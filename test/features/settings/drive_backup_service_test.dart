import 'dart:convert';

import 'package:latitude_tracker/features/settings/services/drive_service_helper.dart';
import 'package:test/test.dart';

void main() {
  group('DriveServiceHelper.filenameFromUrl', () {
    test('extracts UUID from a standard Firebase Storage download URL', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/latitude-tracker-f5d03.appspot.com'
          '/o/users%2FUID%2Fsales%2FsaleId%2Fitems%2FitemId%2Fphotos%2F'
          '9eda0e51-ca3b-4ee0-ad2f-607b5fd1026d.jpg?alt=media&token=abc';
      expect(
        DriveServiceHelper.filenameFromUrl(url),
        '9eda0e51-ca3b-4ee0-ad2f-607b5fd1026d.jpg',
      );
    });

    test('extracts UUID from a repair photo URL', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/latitude-tracker-f5d03.appspot.com'
          '/o/users%2FUID%2Frepairs%2FrepairId%2Fphotos%2F'
          'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg?alt=media&token=xyz';
      expect(
        DriveServiceHelper.filenameFromUrl(url),
        'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg',
      );
    });

    test('falls back gracefully for unexpected URL formats', () {
      const url = 'https://example.com/some/path/photo.jpg?token=abc';
      expect(DriveServiceHelper.filenameFromUrl(url), 'photo.jpg');
    });
  });

  group('DriveServiceHelper.storagePathFromUrl', () {
    test('decodes a SaleItem photo URL to its Storage path', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/latitude-tracker-f5d03.appspot.com'
          '/o/users%2FUID%2Fsales%2FsaleId%2Fitems%2FitemId%2Fphotos%2F'
          '9eda0e51-ca3b-4ee0-ad2f-607b5fd1026d.jpg?alt=media&token=abc';
      expect(
        DriveServiceHelper.storagePathFromUrl(url),
        'users/UID/sales/saleId/items/itemId/photos/'
        '9eda0e51-ca3b-4ee0-ad2f-607b5fd1026d.jpg',
      );
    });

    test('decodes a Repair photo URL to its Storage path', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/latitude-tracker-f5d03.appspot.com'
          '/o/users%2FUID%2Frepairs%2FrepairId%2Fphotos%2F'
          'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg?alt=media&token=xyz';
      expect(
        DriveServiceHelper.storagePathFromUrl(url),
        'users/UID/repairs/repairId/photos/'
        'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg',
      );
    });

    test('throws FormatException for a URL with no /o/ segment', () {
      const url = 'https://example.com/some/path/photo.jpg';
      expect(
        () => DriveServiceHelper.storagePathFromUrl(url),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('DriveServiceHelper.extractPhotos', () {
    test('returns empty list for empty archive', () {
      final json = jsonEncode(<String, dynamic>{
        'sales': <dynamic>[],
        'repairs': <dynamic>[],
      });
      expect(DriveServiceHelper.extractPhotos(json), isEmpty);
    });

    test('extracts SaleItem photos', () {
      final json = jsonEncode(<String, dynamic>{
        'sales': <dynamic>[
          <String, dynamic>{
            'id': 'sale1',
            'items': <dynamic>[
              <String, dynamic>{
                'id': 'item1',
                'photoUrls': <String>[
                  'https://storage/photo1.jpg',
                  'https://storage/photo2.jpg',
                ],
                'components': <dynamic>[],
              },
            ],
          },
        ],
        'repairs': <dynamic>[],
      });

      final entries = DriveServiceHelper.extractPhotos(json);
      expect(entries, hasLength(2));
      expect(
        entries.map((e) => e.url),
        containsAll(<String>[
          'https://storage/photo1.jpg',
          'https://storage/photo2.jpg',
        ]),
      );
    });

    test('extracts ComponentItem photos', () {
      final json = jsonEncode(<String, dynamic>{
        'sales': <dynamic>[
          <String, dynamic>{
            'id': 'sale1',
            'items': <dynamic>[
              <String, dynamic>{
                'id': 'item1',
                'photoUrls': <dynamic>[],
                'components': <dynamic>[
                  <String, dynamic>{
                    'id': 'comp1',
                    'photoUrls': <String>['https://storage/comp-photo.jpg'],
                  },
                ],
              },
            ],
          },
        ],
        'repairs': <dynamic>[],
      });

      final entries = DriveServiceHelper.extractPhotos(json);
      expect(entries, hasLength(1));
      expect(entries.first, isA<ComponentPhoto>());
    });

    test('extracts Repair photos', () {
      final json = jsonEncode(<String, dynamic>{
        'sales': <dynamic>[],
        'repairs': <dynamic>[
          <String, dynamic>{
            'id': 'repair1',
            'photoUrls': <String>['https://storage/repair-photo.jpg'],
          },
        ],
      });

      final entries = DriveServiceHelper.extractPhotos(json);
      expect(entries, hasLength(1));
      expect(entries.first, isA<RepairPhoto>());
    });

    test('collects all three photo types in a single archive', () {
      final json = jsonEncode(<String, dynamic>{
        'sales': <dynamic>[
          <String, dynamic>{
            'id': 'sale1',
            'items': <dynamic>[
              <String, dynamic>{
                'id': 'item1',
                'photoUrls': <String>['https://storage/item-photo.jpg'],
                'components': <dynamic>[
                  <String, dynamic>{
                    'id': 'comp1',
                    'photoUrls': <String>['https://storage/comp-photo.jpg'],
                  },
                ],
              },
            ],
          },
        ],
        'repairs': <dynamic>[
          <String, dynamic>{
            'id': 'repair1',
            'photoUrls': <String>['https://storage/repair-photo.jpg'],
          },
        ],
      });

      final entries = DriveServiceHelper.extractPhotos(json);
      expect(entries, hasLength(3));
      expect(entries.whereType<SaleItemPhoto>(), hasLength(1));
      expect(entries.whereType<ComponentPhoto>(), hasLength(1));
      expect(entries.whereType<RepairPhoto>(), hasLength(1));
    });

    test('skips items or components with missing photoUrls gracefully', () {
      final json = jsonEncode(<String, dynamic>{
        'sales': <dynamic>[
          <String, dynamic>{
            'id': 'sale1',
            'items': <dynamic>[
              <String, dynamic>{
                'id': 'item1',
                // photoUrls absent — treated as empty
                'components': <dynamic>[],
              },
            ],
          },
        ],
        'repairs': <dynamic>[],
      });

      expect(DriveServiceHelper.extractPhotos(json), isEmpty);
    });

    test('returns empty list for malformed JSON', () {
      expect(DriveServiceHelper.extractPhotos('not json at all'), isEmpty);
    });

    test('returns empty list for empty string', () {
      expect(DriveServiceHelper.extractPhotos(''), isEmpty);
    });
  });
}
