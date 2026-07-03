import 'package:latitude_tracker/features/heat_map/services/cp4_coordinates_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';

void main() {
  tearDown(Cp4CoordinatesService.resetOverride);

  group('Cp4CoordinatesService.lookup', () {
    test('returns the coordinates and locality for a known prefix', () async {
      Cp4CoordinatesService.overrideTable({
        '3000': (latLng: const LatLng(40.2033, -8.4103), locality: 'Coimbra'),
      });

      final result = await Cp4CoordinatesService.lookup('3000');

      expect(result, isNotNull);
      expect(result!.latLng.latitude, closeTo(40.2033, 0.0001));
      expect(result.latLng.longitude, closeTo(-8.4103, 0.0001));
      expect(result.locality, 'Coimbra');
    });

    test('returns null for a prefix not in the table', () async {
      Cp4CoordinatesService.overrideTable({
        '3000': (latLng: const LatLng(40.2033, -8.4103), locality: 'Coimbra'),
      });

      final result = await Cp4CoordinatesService.lookup('9999');

      expect(result, isNull);
    });

    test('returns null when the table is empty', () async {
      Cp4CoordinatesService.overrideTable({});

      final result = await Cp4CoordinatesService.lookup('3000');

      expect(result, isNull);
    });
  });
}
