import 'package:latitude_tracker/features/buyers/models/buyer_address.dart';
import 'package:test/test.dart';

BuyerAddress _address({
  String street = 'Rua das Flores',
  String houseNumber = '12',
  String? fraction,
  String postalCode = '4000-123',
  String city = 'Porto',
  String country = 'Portugal',
}) => BuyerAddress(
  id: 'test-id',
  label: 'Casa',
  street: street,
  houseNumber: houseNumber,
  fraction: fraction,
  city: city,
  postalCode: postalCode,
  country: country,
);

void main() {
  group('BuyerAddress.formattedAddress', () {
    test('includes buyer name on the first line', () {
      final result = _address().formattedAddress('Ana Silva');
      expect(result.split('\n').first, 'Ana Silva');
    });

    test('formats street, number, and city lines', () {
      final result = _address().formattedAddress('Ana Silva');
      final lines = result.split('\n');
      expect(lines[1], 'Rua das Flores, 12');
      expect(lines[2], '4000-123 Porto');
    });

    test('omits country line for Portugal', () {
      final result = _address().formattedAddress('Ana Silva');
      expect(result.split('\n').length, 3);
      expect(result, isNot(contains('Portugal')));
    });

    test('omits country line for portugal (case-insensitive)', () {
      final result = _address(
        country: 'portugal',
      ).formattedAddress('Ana Silva');
      expect(result.split('\n').length, 3);
    });

    test('includes country line for non-Portugal addresses', () {
      final result = _address(country: 'France').formattedAddress('Ana Silva');
      final lines = result.split('\n');
      expect(lines.length, 4);
      expect(lines.last, 'France');
    });

    test('includes fraction when set', () {
      final result = _address(fraction: '2º Dto').formattedAddress('Ana Silva');
      expect(result.split('\n')[1], 'Rua das Flores, 12, 2º Dto');
    });

    test('omits fraction when null', () {
      final result = _address().formattedAddress('Ana Silva');
      expect(result.split('\n')[1], 'Rua das Flores, 12');
    });

    test('omits fraction when empty string', () {
      final result = _address(fraction: '').formattedAddress('Ana Silva');
      expect(result.split('\n')[1], 'Rua das Flores, 12');
    });
  });

  group('BuyerAddress.hasMapsAddress', () {
    test('returns true when street, city, and postalCode are non-empty', () {
      expect(_address().hasMapsAddress, isTrue);
    });

    test('returns false when street is empty', () {
      expect(_address(street: '').hasMapsAddress, isFalse);
    });

    test('returns false when city is empty', () {
      expect(_address(city: '').hasMapsAddress, isFalse);
    });

    test('returns false when postalCode is empty', () {
      expect(_address(postalCode: '').hasMapsAddress, isFalse);
    });
  });

  group('BuyerAddress.fromArchiveMap', () {
    test('maps all fields from a well-formed archive map', () {
      final addr = BuyerAddress.fromArchiveMap('b1', {
        'id': 'addr-1',
        'label': 'Casa',
        'street': 'Rua das Flores',
        'houseNumber': '10',
        'fraction': '2º Dto',
        'notes': 'Doorbell broken',
        'city': 'Porto',
        'postalCode': '4000-123',
        'country': 'Portugal',
        'isDefault': true,
      });
      expect(addr.id, 'addr-1');
      expect(addr.buyerId, 'b1');
      expect(addr.label, 'Casa');
      expect(addr.street, 'Rua das Flores');
      expect(addr.houseNumber, '10');
      expect(addr.fraction, '2º Dto');
      expect(addr.notes, 'Doorbell broken');
      expect(addr.city, 'Porto');
      expect(addr.postalCode, '4000-123');
      expect(addr.country, 'Portugal');
      expect(addr.isDefault, isTrue);
    });

    test('null optional fields default correctly', () {
      final addr = BuyerAddress.fromArchiveMap('b1', {
        'id': 'addr-1',
        'label': 'Casa',
        'street': '',
        'houseNumber': '',
        'city': '',
        'postalCode': '',
      });
      expect(addr.fraction, isNull);
      expect(addr.notes, isNull);
      expect(addr.country, 'Portugal');
      expect(addr.isDefault, isFalse);
    });

    test('missing id defaults to empty string', () {
      final addr = BuyerAddress.fromArchiveMap('b1', {
        'label': 'Casa',
        'street': '',
        'houseNumber': '',
        'city': '',
        'postalCode': '',
      });
      expect(addr.id, '');
    });
  });

  group('BuyerAddress.mapsUri', () {
    test('builds a Google Maps URL with the encoded address', () {
      final uri = _address().mapsUri;
      expect(uri.scheme, 'https');
      expect(uri.host, 'maps.google.com');
      expect(uri.path, '/maps');
      expect(uri.queryParameters['q'], contains('Rua das Flores'));
      expect(uri.queryParameters['q'], contains('Porto'));
    });

    test('includes fraction in query when set', () {
      final uri = _address(fraction: '2º Dto').mapsUri;
      expect(uri.queryParameters['q'], contains('2º Dto'));
    });

    test('omits fraction from query when null', () {
      final uri = _address().mapsUri;
      expect(uri.queryParameters['q'], isNot(contains('null')));
    });

    test('omits houseNumber from query when empty', () {
      final uri = _address(houseNumber: '').mapsUri;
      final q = uri.queryParameters['q']!;
      expect(q, isNot(contains('  ')));
      expect(q, startsWith('Rua das Flores,'));
    });

    test('omits country from query for Portugal', () {
      final uri = _address().mapsUri;
      expect(uri.queryParameters['q'], isNot(contains('Portugal')));
    });

    test('includes country in query for non-Portugal addresses', () {
      final uri = _address(country: 'France').mapsUri;
      expect(uri.queryParameters['q'], contains('France'));
    });
  });
}
