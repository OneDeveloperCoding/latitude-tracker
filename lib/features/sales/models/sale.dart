import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:latitude_tracker/core/id_gen.dart';

// Seed categories shown by default in the category picker.
// The user can add their own free-text categories on top of these.
const kDefaultCategories = [
  'Colares',
  'Brincos',
  'Chapéus',
  'Pins',
  'Pregadeiras',
  'Tote Bags',
  'Crachás',
  'Stickers',
];

enum PaymentMethod { mbWay, revolut, paypal, cash, sumup, bankTransfer }

// Display order for pickers — most common digital wallets first.
const List<PaymentMethod> kPaymentMethodOrder = [
  PaymentMethod.mbWay,
  PaymentMethod.revolut,
  PaymentMethod.paypal,
  PaymentMethod.cash,
  PaymentMethod.sumup,
  PaymentMethod.bankTransfer,
];

enum PaymentStatus { paid, unpaid }

enum AssemblyStatus { notStarted, waitingForMaterials, inProgress, ready }

enum DeliveryType { shipping, pickup, handDelivery }

enum ShipmentStatus { pending, shipped, delivered }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.mbWay => 'MB Way',
    PaymentMethod.revolut => 'Revolut',
    PaymentMethod.paypal => 'PayPal',
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

const kMaxComponentQuantity = 9999;

class ComponentItem {
  const ComponentItem({
    required this.id,
    required this.name,
    required this.isAvailable,
    this.quantity = 1,
    this.photoUrls = const [],
    this.notes,
  });

  factory ComponentItem.fromMap(Map<String, dynamic> map) => ComponentItem(
    id: map['id'] as String? ?? newId(),
    name: map['name'] as String? ?? '',
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    isAvailable: map['isAvailable'] as bool? ?? false,
    photoUrls: List<String>.from(map['photoUrls'] as List? ?? []),
    notes: map['notes'] as String?,
  );
  final String id;
  final String name;
  final int quantity;
  final bool isAvailable;
  final List<String> photoUrls;
  final String? notes;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'isAvailable': isAvailable,
    'photoUrls': photoUrls,
    if (notes != null) 'notes': notes,
  };

  ComponentItem copyWith({
    String? name,
    int? quantity,
    bool? isAvailable,
    List<String>? photoUrls,
    Object? notes = _sentinel,
  }) => ComponentItem(
    id: id,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    isAvailable: isAvailable ?? this.isAvailable,
    photoUrls: photoUrls ?? this.photoUrls,
    notes: notes == _sentinel ? this.notes : notes as String?,
  );

  ComponentItem adjustedQuantity(int delta) =>
      copyWith(quantity: (quantity + delta).clamp(1, kMaxComponentQuantity));
}

const _sentinel = Object();

class SaleItem {
  const SaleItem({
    required this.id,
    required this.description,
    required this.category,
    required this.price,
    required this.assemblyStatus,
    this.components = const [],
    this.photoUrls = const [],
  });

  factory SaleItem.fromMap(Map<String, dynamic> map) => SaleItem(
    id: map['id'] as String? ?? '',
    description: map['description'] as String? ?? '',
    category: map['category'] as String? ?? kDefaultCategories.first,
    price: (map['price'] as num?)?.toDouble() ?? 0.0,
    assemblyStatus: AssemblyStatus.values.firstWhere(
      (e) => e.name == map['assemblyStatus'],
      orElse: () => AssemblyStatus.notStarted,
    ),
    components: (map['components'] as List<dynamic>? ?? [])
        .map((e) => ComponentItem.fromMap(e as Map<String, dynamic>))
        .toList(),
    photoUrls: List<String>.from(map['photoUrls'] as List? ?? []),
  );
  final String id;
  final String description;
  final String category;
  final double price;
  final AssemblyStatus assemblyStatus;
  final List<ComponentItem> components;
  final List<String> photoUrls;

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'category': category,
    'price': price,
    'assemblyStatus': assemblyStatus.name,
    'components': components.map((c) => c.toMap()).toList(),
    'photoUrls': photoUrls,
  };

  SaleItem copyWith({
    String? description,
    String? category,
    double? price,
    AssemblyStatus? assemblyStatus,
    List<ComponentItem>? components,
    List<String>? photoUrls,
  }) => SaleItem(
    id: id,
    description: description ?? this.description,
    category: category ?? this.category,
    price: price ?? this.price,
    assemblyStatus: assemblyStatus ?? this.assemblyStatus,
    components: components ?? this.components,
    photoUrls: photoUrls ?? this.photoUrls,
  );
}

class SalePayment {
  const SalePayment({required this.status, required this.method});

  factory SalePayment.fromMap(Map<String, dynamic> map) => SalePayment(
    status: PaymentStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => PaymentStatus.unpaid,
    ),
    method: PaymentMethod.values.firstWhere(
      (e) => e.name == map['method'],
      orElse: () => PaymentMethod.cash,
    ),
  );
  final PaymentStatus status;
  final PaymentMethod method;

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
  const SaleShipment({
    required this.type,
    required this.status,
    this.trackingCode,
    this.addressId,
    this.postalCode,
  });

  factory SaleShipment.fromMap(Map<String, dynamic> map) => SaleShipment(
    type: DeliveryType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => DeliveryType.shipping,
    ),
    status: ShipmentStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => ShipmentStatus.pending,
    ),
    trackingCode: map['trackingCode'] as String?,
    addressId: map['addressId'] as String?,
    postalCode: map['postalCode'] as String?,
  );
  final DeliveryType type;
  final ShipmentStatus status;
  final String? trackingCode;
  final String? addressId;
  final String? postalCode;

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
  }) => SaleShipment(
    type: type,
    status: status ?? this.status,
    trackingCode: trackingCode ?? this.trackingCode,
    addressId: addressId ?? this.addressId,
    postalCode: postalCode ?? this.postalCode,
  );
}

class Sale {
  const Sale({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.items,
    required this.payment,
    required this.shipment,
    required this.requiresNif,
    required this.createdAt,
    this.atSubmissionDone = false,
    this.scheduledDate,
    this.notes,
  });

  factory Sale.fromArchiveMap(Map<String, dynamic> map) => Sale(
    id: map['id'] as String? ?? '',
    buyerId: map['buyerId'] as String? ?? '',
    buyerName: map['buyerName'] as String? ?? '',
    items: (map['items'] as List<dynamic>? ?? [])
        .map((e) => SaleItem.fromMap(e as Map<String, dynamic>))
        .toList(),
    payment: SalePayment.fromMap(
      (map['payment'] as Map<String, dynamic>?) ?? const {},
    ),
    shipment: SaleShipment.fromMap(
      (map['shipment'] as Map<String, dynamic>?) ?? const {},
    ),
    requiresNif: map['requiresNif'] as bool? ?? false,
    atSubmissionDone: map['atSubmissionDone'] as bool? ?? false,
    createdAt: _parseArchiveDate(map['createdAt']),
    scheduledDate: map['scheduledDate'] != null
        ? _parseArchiveDate(map['scheduledDate'])
        : null,
    notes: map['notes'] as String?,
  );

  factory Sale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Sale(
      id: doc.id,
      buyerId: data['buyerId'] as String? ?? '',
      buyerName: data['buyerName'] as String? ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => SaleItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      payment: SalePayment.fromMap(
        (data['payment'] as Map<String, dynamic>?) ?? const {},
      ),
      shipment: SaleShipment.fromMap(
        (data['shipment'] as Map<String, dynamic>?) ?? const {},
      ),
      requiresNif: data['requiresNif'] as bool? ?? false,
      atSubmissionDone: data['atSubmissionDone'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String?,
    );
  }
  final String id;
  final String buyerId;
  final String buyerName;
  final List<SaleItem> items;
  final SalePayment payment;
  final SaleShipment shipment;
  final bool requiresNif;
  final bool atSubmissionDone;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final String? notes;

  double get totalPrice => items.fold(0, (acc, item) => acc + item.price);

  // Worst-case across all items: waitingForMaterials > inProgress > notStarted
  // > ready.
  // A Sale is only ready when every SaleItem is ready.
  AssemblyStatus get derivedAssemblyStatus {
    if (items.isEmpty) return AssemblyStatus.notStarted;
    var worst = AssemblyStatus.ready;
    for (final item in items) {
      final s = item.assemblyStatus;
      if (s == AssemblyStatus.waitingForMaterials) {
        return AssemblyStatus.waitingForMaterials;
      }
      if (s == AssemblyStatus.inProgress) {
        worst = AssemblyStatus.inProgress;
      } else if (s == AssemblyStatus.notStarted &&
          worst != AssemblyStatus.inProgress) {
        worst = AssemblyStatus.notStarted;
      }
    }
    return worst;
  }

  static DateTime _parseArchiveDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (value is Map && value['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['_seconds'] as int) * 1000,
      );
    }
    // Sentinel for unrecognised/missing dates — keeps corrupt docs out of
    // current-period aggregations without losing them from the list entirely.
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Map<String, dynamic> toFirestore() => {
    'buyerId': buyerId,
    'buyerName': buyerName,
    'items': items.map((item) => item.toMap()).toList(),
    'payment': payment.toMap(),
    'shipment': shipment.toMap(),
    'requiresNif': requiresNif,
    'atSubmissionDone': atSubmissionDone,
    'createdAt': Timestamp.fromDate(createdAt),
    'scheduledDate': scheduledDate != null
        ? Timestamp.fromDate(scheduledDate!)
        : null,
    'notes': notes,
  };

  // Nullable fields use a sentinel to distinguish "clear to null" from "not
  // provided".
  Sale copyWith({
    List<SaleItem>? items,
    SalePayment? payment,
    SaleShipment? shipment,
    bool? requiresNif,
    bool? atSubmissionDone,
    Object? scheduledDate = _unset,
    Object? notes = _unset,
  }) => Sale(
    id: id,
    buyerId: buyerId,
    buyerName: buyerName,
    items: items ?? this.items,
    payment: payment ?? this.payment,
    shipment: shipment ?? this.shipment,
    requiresNif: requiresNif ?? this.requiresNif,
    atSubmissionDone: atSubmissionDone ?? this.atSubmissionDone,
    createdAt: createdAt,
    scheduledDate: scheduledDate == _unset
        ? this.scheduledDate
        : scheduledDate as DateTime?,
    notes: notes == _unset ? this.notes : notes as String?,
  );
}

const _unset = Object();

// Half-open interval [start, end): inclusive start, exclusive end.
extension SaleInPeriod on Sale {
  bool inPeriod(DateTime start, DateTime end) =>
      !createdAt.isBefore(start) && createdAt.isBefore(end);
}
