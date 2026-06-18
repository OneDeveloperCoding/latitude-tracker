import 'package:cloud_firestore/cloud_firestore.dart';

class Buyer {
  const Buyer({
    required this.id,
    required this.name,
    required this.createdAt,
    this.instagramHandle,
    this.phone,
    this.nif,
    this.tags = const [],
    this.notes,
  });

  factory Buyer.fromArchiveMap(Map<String, dynamic> map) => Buyer(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    instagramHandle: map['instagramHandle'] as String?,
    phone: map['phone'] as String?,
    nif: map['nif'] as String?,
    tags: List<String>.from(map['tags'] as List? ?? []),
    notes: map['notes'] as String?,
    createdAt:
        DateTime.tryParse(map['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory Buyer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
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
  final String id;
  final String name;
  final String? instagramHandle;
  final String? phone;
  final String? nif;
  final List<String> tags;
  final String? notes;
  final DateTime createdAt;

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
  }) => Buyer(
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
