import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/buyers/models/buyer_address.dart';

BuyerAddress _address({
  String street = 'Rua das Flores',
  String houseNumber = '12',
  String? fraction,
  String postalCode = '4000-123',
  String city = 'Porto',
  String country = 'Portugal',
}) =>
    BuyerAddress(
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
      final result = _address(country: 'Portugal').formattedAddress('Ana Silva');
      expect(result.split('\n').length, 3);
      expect(result, isNot(contains('Portugal')));
    });

    test('omits country line for portugal (case-insensitive)', () {
      final result = _address(country: 'portugal').formattedAddress('Ana Silva');
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
      final result = _address(fraction: null).formattedAddress('Ana Silva');
      expect(result.split('\n')[1], 'Rua das Flores, 12');
    });

    test('omits fraction when empty string', () {
      final result = _address(fraction: '').formattedAddress('Ana Silva');
      expect(result.split('\n')[1], 'Rua das Flores, 12');
    });
  });
}
