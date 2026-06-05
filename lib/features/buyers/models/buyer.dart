import 'package:cloud_firestore/cloud_firestore.dart';

class Buyer {
  final String id;
  final String name;
  final String? instagramHandle;
  final String? phone;
  final String? nif;
  final List<String> tags;
  final String? notes;
  final DateTime createdAt;

  const Buyer({
    required this.id,
    required this.name,
    this.instagramHandle,
    this.phone,
    this.nif,
    this.tags = const [],
    this.notes,
    required this.createdAt,
  });

  factory Buyer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Buyer(
      id: doc.id,
      name: data['name'] as String? ?? '',
      instagramHandle: data['instagramHandle'] as String?,
      phone: data['phone'] as String?,
      nif: data['nif'] as String?,
      tags: List<String>.from(data['tags'] as List? ?? []),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'instagramHandle': instagramHandle,
        'phone': phone,
        'nif': nif,
        'tags': tags,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Buyer copyWith({
    String? name,
    String? instagramHandle,
    String? phone,
    String? nif,
    List<String>? tags,
    Object? notes = _unset,
  }) =>
      Buyer(
        id: id,
        name: name ?? this.name,
        instagramHandle: instagramHandle ?? this.instagramHandle,
        phone: phone ?? this.phone,
        nif: nif ?? this.nif,
        tags: tags ?? this.tags,
        notes: notes == _unset ? this.notes : notes as String?,
        createdAt: createdAt,
      );
}

const _unset = Object();
