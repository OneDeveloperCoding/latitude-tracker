import 'package:cloud_firestore/cloud_firestore.dart';

class BuyerAddress {
  final String id;
  final String label;
  final String street;
  final String houseNumber;
  final String? fraction;
  final String? notes;
  final String city;
  final String postalCode;
  final String country;
  final bool isDefault;

  const BuyerAddress({
    required this.id,
    required this.label,
    required this.street,
    required this.houseNumber,
    this.fraction,
    this.notes,
    required this.city,
    required this.postalCode,
    this.country = 'Portugal',
    this.isDefault = false,
  });

  factory BuyerAddress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BuyerAddress(
      id: doc.id,
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

  BuyerAddress copyWith({
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
