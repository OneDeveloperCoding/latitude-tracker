import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:latitude_tracker/features/sales/models/sale.dart';

enum RepairStatus {
  received,
  waitingForMaterials,
  inProgress,
  done,
  returned,
}

class RepairReturnDelivery {
  const RepairReturnDelivery({
    required this.type,
    required this.status,
    this.trackingCode,
    this.postalCode,
  });

  factory RepairReturnDelivery.fromMap(Map<String, dynamic> map) =>
      RepairReturnDelivery(
        type: DeliveryType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => DeliveryType.shipping,
        ),
        status: ShipmentStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => ShipmentStatus.pending,
        ),
        trackingCode: map['trackingCode'] as String?,
        postalCode: map['postalCode'] as String?,
      );
  final DeliveryType type;
  final ShipmentStatus status;
  final String? trackingCode;
  final String? postalCode;

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'status': status.name,
    'trackingCode': trackingCode,
    'postalCode': postalCode,
  };

  RepairReturnDelivery copyWith({
    DeliveryType? type,
    ShipmentStatus? status,
    Object? trackingCode = _unset,
    Object? postalCode = _unset,
  }) => RepairReturnDelivery(
    type: type ?? this.type,
    status: status ?? this.status,
    trackingCode: trackingCode == _unset
        ? this.trackingCode
        : trackingCode as String?,
    postalCode: postalCode == _unset ? this.postalCode : postalCode as String?,
  );
}

class Repair {
  const Repair({
    required this.id,
    required this.itemDescription,
    required this.itemCategory,
    required this.problemDescription,
    required this.status,
    required this.payment,
    required this.returnDelivery,
    required this.createdAt,
    this.buyerId,
    this.buyerName,
    this.freeTextContact,
    this.linkedSaleId,
    this.workDone = '',
    this.materialsCost,
    this.photoUrls = const [],
  }) : assert(
         buyerId != null || freeTextContact != null,
         'A Repair must have either a buyerId or a freeTextContact',
       );

  factory Repair.fromArchiveMap(Map<String, dynamic> map) => Repair(
    id: map['id'] as String? ?? '',
    buyerId: map['buyerId'] as String?,
    buyerName: map['buyerName'] as String?,
    // If buyerId is absent, freeTextContact must be non-null to satisfy the
    // constructor assert. Fall back to '' rather than letting both be null.
    freeTextContact: map['buyerId'] == null
        ? (map['freeTextContact'] as String? ?? '')
        : map['freeTextContact'] as String?,
    linkedSaleId: map['linkedSaleId'] as String?,
    itemDescription: map['itemDescription'] as String? ?? '',
    itemCategory: map['itemCategory'] as String? ?? '',
    problemDescription: map['problemDescription'] as String? ?? '',
    workDone: map['workDone'] as String? ?? '',
    materialsCost: (map['materialsCost'] as num?)?.toDouble(),
    status: RepairStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => RepairStatus.received,
    ),
    payment: SalePayment.fromMap(
      (map['payment'] as Map<String, dynamic>?) ?? const {},
    ),
    returnDelivery: RepairReturnDelivery.fromMap(
      (map['returnDelivery'] as Map<String, dynamic>?) ?? const {},
    ),
    photoUrls: List<String>.from(map['photoUrls'] as List? ?? []),
    createdAt: _parseArchiveDate(map['createdAt']),
  );

  factory Repair.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Repair(
      id: doc.id,
      buyerId: data['buyerId'] as String?,
      buyerName: data['buyerName'] as String?,
      freeTextContact: data['buyerId'] == null
          ? (data['freeTextContact'] as String? ?? '')
          : data['freeTextContact'] as String?,
      linkedSaleId: data['linkedSaleId'] as String?,
      itemDescription: data['itemDescription'] as String? ?? '',
      itemCategory: data['itemCategory'] as String? ?? '',
      problemDescription: data['problemDescription'] as String? ?? '',
      workDone: data['workDone'] as String? ?? '',
      materialsCost: (data['materialsCost'] as num?)?.toDouble(),
      status: RepairStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RepairStatus.received,
      ),
      payment: SalePayment.fromMap(
        (data['payment'] as Map<String, dynamic>?) ?? const {},
      ),
      returnDelivery: RepairReturnDelivery.fromMap(
        (data['returnDelivery'] as Map<String, dynamic>?) ?? const {},
      ),
      photoUrls: List<String>.from(data['photoUrls'] as List? ?? []),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
  final String id;

  // Contact: at least one of buyerId or freeTextContact is non-null.
  final String? buyerId;
  final String? buyerName;
  final String? freeTextContact;

  final String? linkedSaleId;

  final String itemDescription;
  final String itemCategory;
  final String problemDescription;
  final String workDone;
  final double? materialsCost;

  final RepairStatus status;
  final SalePayment payment;
  final RepairReturnDelivery returnDelivery;

  final List<String> photoUrls;
  final DateTime createdAt;

  // Display name for the contact regardless of type.
  String get contactName => buyerName ?? freeTextContact ?? '';

  bool get isLinkedToBuyer => buyerId != null;

  // A Repair is active (shown in default list) unless returned AND delivery
  // confirmed.
  bool get isActive =>
      !(status == RepairStatus.returned &&
          returnDelivery.status == ShipmentStatus.delivered);

  static DateTime _parseArchiveDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (value is Map && value['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['_seconds'] as int) * 1000,
      );
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Map<String, dynamic> toFirestore() => {
    'buyerId': buyerId,
    'buyerName': buyerName,
    'freeTextContact': freeTextContact,
    'linkedSaleId': linkedSaleId,
    'itemDescription': itemDescription,
    'itemCategory': itemCategory,
    'problemDescription': problemDescription,
    'workDone': workDone,
    'materialsCost': materialsCost,
    'status': status.name,
    'payment': payment.toMap(),
    'returnDelivery': returnDelivery.toMap(),
    'photoUrls': photoUrls,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  Repair copyWith({
    String? itemDescription,
    String? itemCategory,
    String? problemDescription,
    String? workDone,
    Object? materialsCost = _unset,
    Object? linkedSaleId = _unset,
    RepairStatus? status,
    SalePayment? payment,
    RepairReturnDelivery? returnDelivery,
    List<String>? photoUrls,
    // Contact fields intentionally excluded — changing contact creates a new
    // Repair
  }) => Repair(
    id: id,
    buyerId: buyerId,
    buyerName: buyerName,
    freeTextContact: freeTextContact,
    linkedSaleId: linkedSaleId == _unset
        ? this.linkedSaleId
        : linkedSaleId as String?,
    itemDescription: itemDescription ?? this.itemDescription,
    itemCategory: itemCategory ?? this.itemCategory,
    problemDescription: problemDescription ?? this.problemDescription,
    workDone: workDone ?? this.workDone,
    materialsCost: materialsCost == _unset
        ? this.materialsCost
        : materialsCost as double?,
    status: status ?? this.status,
    payment: payment ?? this.payment,
    returnDelivery: returnDelivery ?? this.returnDelivery,
    photoUrls: photoUrls ?? this.photoUrls,
    createdAt: createdAt,
  );
}

const _unset = Object();
