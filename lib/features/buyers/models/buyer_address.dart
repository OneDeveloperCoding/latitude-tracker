import 'package:cloud_firestore/cloud_firestore.dart';

class BuyerAddress {

  const BuyerAddress({
    required this.id,
    required this.label, required this.street, required this.houseNumber, required this.city, required this.postalCode, this.buyerId = '',
    this.fraction,
    this.notes,
    this.country = defaultCountry,
    this.isDefault = false,
  });

  factory BuyerAddress.fromArchiveMap(String buyerId, Map<String, dynamic> map) =>
      BuyerAddress(
        id: map['id'] as String? ?? '',
        buyerId: buyerId,
        label: map['label'] as String? ?? '',
        street: map['street'] as String? ?? '',
        houseNumber: map['houseNumber'] as String? ?? '',
        fraction: map['fraction'] as String?,
        notes: map['notes'] as String?,
        city: map['city'] as String? ?? '',
        postalCode: map['postalCode'] as String? ?? '',
        country: map['country'] as String? ?? 'Portugal',
        isDefault: map['isDefault'] as bool? ?? false,
      );

  factory BuyerAddress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BuyerAddress(
      id: doc.id,
      buyerId: doc.reference.parent.parent?.id ?? '',
      label: data['label'] as String,
      street: data['street'] as String? ?? '',
      houseNumber: data['houseNumber'] as String? ?? '',
      fraction: data['fraction'] as String?,
      notes: data['notes'] as String?,
      city: data['city'] as String? ?? '',
      postalCode: data['postalCode'] as String,
      country: data['country'] as String? ?? 'Portugal',
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }
  static const defaultCountry = 'Portugal';

  final String id;
  final String buyerId;
  final String label;
  final String street;
  final String houseNumber;
  final String? fraction;
  final String? notes;
  final String city;
  final String postalCode;
  final String country;
  final bool isDefault;

  Map<String, dynamic> toFirestore() => {
        'label': label,
        'street': street,
        'houseNumber': houseNumber,
        'fraction': fraction,
        'notes': notes,
        'city': city,
        'postalCode': postalCode,
        'country': country,
        'isDefault': isDefault,
      };

  bool get hasMapsAddress =>
      street.isNotEmpty && city.isNotEmpty && postalCode.isNotEmpty;

  Uri get mapsUri {
    final streetLine = [street, if (houseNumber.isNotEmpty) houseNumber].join(' ');
    final parts = [
      streetLine,
      if (fraction?.isNotEmpty == true) fraction!,
      '$postalCode $city',
      if (country.toLowerCase() != 'portugal') country,
    ];
    return Uri.parse(
        'https://maps.google.com/maps?q=${Uri.encodeComponent(parts.join(', '))}');
  }

  String formattedAddress(String buyerName) {
    final streetLine = [street, houseNumber, if (fraction?.isNotEmpty == true) fraction!]
        .join(', ');
    final postalLine = '$postalCode $city';
    return [
      buyerName,
      streetLine,
      postalLine,
      if (country.toLowerCase() != 'portugal') country,
    ].join('\n');
  }

  BuyerAddress copyWith({
    String? buyerId,
    String? label,
    String? street,
    String? houseNumber,
    String? fraction,
    String? notes,
    String? city,
    String? postalCode,
    String? country,
    bool? isDefault,
  }) =>
      BuyerAddress(
        id: id,
        buyerId: buyerId ?? this.buyerId,
        label: label ?? this.label,
        street: street ?? this.street,
        houseNumber: houseNumber ?? this.houseNumber,
        fraction: fraction ?? this.fraction,
        notes: notes ?? this.notes,
        city: city ?? this.city,
        postalCode: postalCode ?? this.postalCode,
        country: country ?? this.country,
        isDefault: isDefault ?? this.isDefault,
      );
}
