import 'package:cloud_firestore/cloud_firestore.dart';

class Buyer {
  final String id;
  final String name;
  final String? instagramHandle;
  final String? phone;
  final String? nif;
  final DateTime createdAt;

  const Buyer({
    required this.id,
    required this.name,
    this.instagramHandle,
    this.phone,
    this.nif,
    required this.createdAt,
  });

  factory Buyer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Buyer(
      id: doc.id,
      name: data['name'] as String,
      instagramHandle: data['instagramHandle'] as String?,
      phone: data['phone'] as String?,
      nif: data['nif'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'instagramHandle': instagramHandle,
        'phone': phone,
        'nif': nif,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Buyer copyWith({
    String? name,
    String? instagramHandle,
    String? phone,
    String? nif,
  }) =>
      Buyer(
        id: id,
        name: name ?? this.name,
        instagramHandle: instagramHandle ?? this.instagramHandle,
        phone: phone ?? this.phone,
        nif: nif ?? this.nif,
        createdAt: createdAt,
      );
}
