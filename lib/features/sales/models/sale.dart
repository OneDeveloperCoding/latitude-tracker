import 'package:cloud_firestore/cloud_firestore.dart';

// Seed categories shown by default in the category picker.
// The user can add their own free-text categories on top of these.
const kDefaultCategories = ['necklace', 'earring', 'tote bag', 'hat'];

enum PaymentMethod { mbWay, cash, sumup, bankTransfer }

enum PaymentStatus { paid, unpaid }

enum AssemblyStatus { notStarted, waitingForMaterials, inProgress, ready }

enum DeliveryType { shipping, pickup }

enum ShipmentStatus { pending, shipped, delivered }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.mbWay => 'MB Way',
        PaymentMethod.cash => 'Cash',
        PaymentMethod.sumup => 'SumUp',
        PaymentMethod.bankTransfer => 'Bank Transfer',
      };
}

extension AssemblyStatusLabel on AssemblyStatus {
  String get label => switch (this) {
        AssemblyStatus.notStarted => 'Not started',
        AssemblyStatus.waitingForMaterials => 'Waiting for materials',
        AssemblyStatus.inProgress => 'In progress',
        AssemblyStatus.ready => 'Ready',
      };
}

extension ShipmentStatusLabel on ShipmentStatus {
  String get label => switch (this) {
        ShipmentStatus.pending => 'Pending',
        ShipmentStatus.shipped => 'Shipped',
        ShipmentStatus.delivered => 'Delivered',
      };
}

class ComponentItem {
  final String id;
  final String name;
  final bool isAvailable;

  const ComponentItem({
    required this.id,
    required this.name,
    required this.isAvailable,
  });

  factory ComponentItem.fromMap(Map<String, dynamic> map) => ComponentItem(
        id: map['id'] as String,
        name: map['name'] as String,
        isAvailable: map['isAvailable'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'isAvailable': isAvailable,
      };

  ComponentItem copyWith({String? name, bool? isAvailable}) => ComponentItem(
        id: id,
        name: name ?? this.name,
        isAvailable: isAvailable ?? this.isAvailable,
      );
}

class SalePayment {
  final PaymentStatus status;
  final PaymentMethod method;

  const SalePayment({required this.status, required this.method});

  factory SalePayment.fromMap(Map<String, dynamic> map) => SalePayment(
        status: PaymentStatus.values.byName(map['status'] as String),
        method: PaymentMethod.values.byName(map['method'] as String),
      );

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'method': method.name,
      };

  SalePayment copyWith({PaymentStatus? status, PaymentMethod? method}) =>
      SalePayment(
        status: status ?? this.status,
        method: method ?? this.method,
      );
}

class SaleShipment {
  final DeliveryType type;
  final ShipmentStatus status;
  final String? trackingCode;
  final String? addressId;
  final String? postalCode;

  const SaleShipment({
    required this.type,
    required this.status,
    this.trackingCode,
    this.addressId,
    this.postalCode,
  });

  factory SaleShipment.fromMap(Map<String, dynamic> map) => SaleShipment(
        type: DeliveryType.values.byName(map['type'] as String),
        status: ShipmentStatus.values.byName(map['status'] as String),
        trackingCode: map['trackingCode'] as String?,
        addressId: map['addressId'] as String?,
        postalCode: map['postalCode'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'status': status.name,
        'trackingCode': trackingCode,
        'addressId': addressId,
        'postalCode': postalCode,
      };

  SaleShipment copyWith({
    ShipmentStatus? status,
    String? trackingCode,
    String? addressId,
    String? postalCode,
  }) =>
      SaleShipment(
        type: type,
        status: status ?? this.status,
        trackingCode: trackingCode ?? this.trackingCode,
        addressId: addressId ?? this.addressId,
        postalCode: postalCode ?? this.postalCode,
      );
}

class Sale {
  final String id;
  final String buyerId;
  final String buyerName;
  final String itemDescription;
  final String category;
  final List<String> photoUrls;
  final double price;
  final AssemblyStatus assemblyStatus;
  final List<ComponentItem> components;
  final SalePayment payment;
  final SaleShipment shipment;
  final bool requiresNif;
  final bool atSubmissionDone;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final String? notes;

  const Sale({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.itemDescription,
    required this.category,
    this.photoUrls = const [],
    required this.price,
    required this.assemblyStatus,
    required this.components,
    required this.payment,
    required this.shipment,
    required this.requiresNif,
    this.atSubmissionDone = false,
    required this.createdAt,
    this.scheduledDate,
    this.notes,
  });

  factory Sale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sale(
      id: doc.id,
      buyerId: data['buyerId'] as String,
      buyerName: data['buyerName'] as String,
      itemDescription: data['itemDescription'] as String,
      category: data['category'] as String? ?? kDefaultCategories.first,
      photoUrls: List<String>.from(data['photoUrls'] as List? ?? []),
      price: (data['price'] as num).toDouble(),
      assemblyStatus:
          AssemblyStatus.values.byName(data['assemblyStatus'] as String),
      components: (data['components'] as List<dynamic>? ?? [])
          .map((e) => ComponentItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      payment: SalePayment.fromMap(data['payment'] as Map<String, dynamic>),
      shipment: SaleShipment.fromMap(data['shipment'] as Map<String, dynamic>),
      requiresNif: data['requiresNif'] as bool? ?? false,
      atSubmissionDone: data['atSubmissionDone'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      scheduledDate: data['scheduledDate'] != null
          ? (data['scheduledDate'] as Timestamp).toDate()
          : null,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'buyerId': buyerId,
        'buyerName': buyerName,
        'itemDescription': itemDescription,
        'category': category,
        'photoUrls': photoUrls,
        'price': price,
        'assemblyStatus': assemblyStatus.name,
        'components': components.map((c) => c.toMap()).toList(),
        'payment': payment.toMap(),
        'shipment': shipment.toMap(),
        'requiresNif': requiresNif,
        'atSubmissionDone': atSubmissionDone,
        'createdAt': Timestamp.fromDate(createdAt),
        'scheduledDate':
            scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
        'notes': notes,
      };

  // Nullable fields use a sentinel to distinguish "clear to null" from "not provided".
  Sale copyWith({
    String? itemDescription,
    String? category,
    List<String>? photoUrls,
    double? price,
    AssemblyStatus? assemblyStatus,
    List<ComponentItem>? components,
    SalePayment? payment,
    SaleShipment? shipment,
    bool? requiresNif,
    bool? atSubmissionDone,
    Object? scheduledDate = _unset,
    Object? notes = _unset,
  }) =>
      Sale(
        id: id,
        buyerId: buyerId,
        buyerName: buyerName,
        itemDescription: itemDescription ?? this.itemDescription,
        category: category ?? this.category,
        photoUrls: photoUrls ?? this.photoUrls,
        price: price ?? this.price,
        assemblyStatus: assemblyStatus ?? this.assemblyStatus,
        components: components ?? this.components,
        payment: payment ?? this.payment,
        shipment: shipment ?? this.shipment,
        requiresNif: requiresNif ?? this.requiresNif,
        atSubmissionDone: atSubmissionDone ?? this.atSubmissionDone,
        createdAt: createdAt,
        scheduledDate:
            scheduledDate == _unset ? this.scheduledDate : scheduledDate as DateTime?,
        notes: notes == _unset ? this.notes : notes as String?,
      );

  // Derives AssemblyStatus from components + current status.
  // waitingForMaterials is never auto-changed — the user controls it manually.
  static AssemblyStatus deriveAssemblyStatus(
    List<ComponentItem> components,
    AssemblyStatus current,
  ) {
    if (current == AssemblyStatus.waitingForMaterials) return current;
    final allAvailable =
        components.isNotEmpty && components.every((c) => c.isAvailable);
    if (allAvailable &&
        (current == AssemblyStatus.notStarted ||
            current == AssemblyStatus.inProgress)) {
      return AssemblyStatus.ready;
    }
    if (!allAvailable && current == AssemblyStatus.ready) {
      return AssemblyStatus.inProgress;
    }
    return current;
  }

  Sale withUpdatedComponents(List<ComponentItem> updated) => copyWith(
        components: updated,
        assemblyStatus: deriveAssemblyStatus(updated, assemblyStatus),
      );
}

const _unset = Object();
