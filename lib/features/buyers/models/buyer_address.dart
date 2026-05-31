import 'package:cloud_firestore/cloud_firestore.dart';

class BuyerAddress {
  final String id;
  final String label;
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final bool isDefault;

  const BuyerAddress({
    required this.id,
    required this.label,
    required this.street,
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
      street: data['street'] as String,
      city: data['city'] as String,
      postalCode: data['postalCode'] as String,
      country: data['country'] as String? ?? 'Portugal',
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'label': label,
        'street': street,
        'city': city,
        'postalCode': postalCode,
        'country': country,
        'isDefault': isDefault,
      };

  BuyerAddress copyWith({
    String? label,
    String? street,
    String? city,
    String? postalCode,
    String? country,
    bool? isDefault,
  }) =>
      BuyerAddress(
        id: id,
        label: label ?? this.label,
        street: street ?? this.street,
        city: city ?? this.city,
        postalCode: postalCode ?? this.postalCode,
        country: country ?? this.country,
        isDefault: isDefault ?? this.isDefault,
      );
}
