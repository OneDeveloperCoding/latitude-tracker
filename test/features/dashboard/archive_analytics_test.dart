import 'package:test/test.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';

Map<String, dynamic> _baseSaleMap({
  String id = 'sale-1',
  String createdAt = '2024-03-15T10:30:00.000Z',
  String? scheduledDate,
  String paymentStatus = 'paid',
  String paymentMethod = 'mbWay',
}) =>
    {
      'id': id,
      'buyerId': 'buyer-1',
      'buyerName': 'Alice',
      'items': [
        {
          'id': 'item-1',
          'description': 'Colar prata',
          'category': 'Colares',
          'price': 45.0,
          'assemblyStatus': 'ready',
          'components': [],
          'photoUrls': [],
        }
      ],
      'payment': {'status': paymentStatus, 'method': paymentMethod},
      'shipment': {
        'type': 'shipping',
        'status': 'delivered',
        'trackingCode': null,
        'addressId': null,
        'postalCode': '1000-001',
      },
      'requiresNif': false,
      'atSubmissionDone': false,
      'createdAt': createdAt,
      'scheduledDate': scheduledDate,
      'notes': null,
    };

Map<String, dynamic> _baseRepairMap({
  String id = 'repair-1',
  String createdAt = '2024-06-01T09:00:00.000Z',
  String? buyerId = 'buyer-1',
  String? buyerName = 'Alice',
  String? freeTextContact,
  double? materialsCost,
}) =>
    {
      'id': id,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'freeTextContact': freeTextContact,
      'linkedSaleId': null,
      'itemDescription': 'Colar dourado',
      'itemCategory': 'Colares',
      'problemDescription': 'Fecho partido',
      'workDone': 'Fecho substituído',
      'materialsCost': materialsCost,
      'status': 'done',
      'payment': {'status': 'paid', 'method': 'cash'},
      'returnDelivery': {
        'type': 'pickup',
        'status': 'pending',
        'trackingCode': null,
        'postalCode': null,
      },
      'photoUrls': [],
      'createdAt': createdAt,
    };

void main() {
  group('Sale.fromArchiveMap', () {
    test('parses ISO-8601 createdAt', () {
      final sale = Sale.fromArchiveMap(_baseSaleMap());
      expect(sale.createdAt, DateTime.parse('2024-03-15T10:30:00.000Z'));
    });

    test('parses Firestore timestamp format as fallback', () {
      final map = _baseSaleMap()
        ..['createdAt'] = {'_seconds': 1710494400, '_nanoseconds': 0};
      final sale = Sale.fromArchiveMap(map);
      expect(sale.createdAt,
          DateTime.fromMillisecondsSinceEpoch(1710494400 * 1000));
    });

    test('parses nullable scheduledDate when present', () {
      final map = _baseSaleMap(scheduledDate: '2024-04-01T00:00:00.000Z');
      final sale = Sale.fromArchiveMap(map);
      expect(sale.scheduledDate, DateTime.parse('2024-04-01T00:00:00.000Z'));
    });

    test('scheduledDate is null when absent', () {
      final sale = Sale.fromArchiveMap(_baseSaleMap());
      expect(sale.scheduledDate, isNull);
    });

    test('parses items list with correct count and content', () {
      final sale = Sale.fromArchiveMap(_baseSaleMap());
      expect(sale.items, hasLength(1));
      expect(sale.items.first.description, 'Colar prata');
      expect(sale.items.first.price, 45.0);
      expect(sale.items.first.category, 'Colares');
    });

    test('parses payment status and method', () {
      final sale = Sale.fromArchiveMap(
          _baseSaleMap(paymentStatus: 'unpaid', paymentMethod: 'cash'));
      expect(sale.payment.status, PaymentStatus.unpaid);
      expect(sale.payment.method, PaymentMethod.cash);
    });

    test('defaults to empty string for missing id', () {
      final map = _baseSaleMap()..remove('id');
      final sale = Sale.fromArchiveMap(map);
      expect(sale.id, '');
    });

    test('defaults requiresNif to false when absent', () {
      final map = _baseSaleMap()..remove('requiresNif');
      final sale = Sale.fromArchiveMap(map);
      expect(sale.requiresNif, isFalse);
    });
  });

  group('Repair.fromArchiveMap', () {
    test('parses ISO-8601 createdAt', () {
      final repair = Repair.fromArchiveMap(_baseRepairMap());
      expect(repair.createdAt, DateTime.parse('2024-06-01T09:00:00.000Z'));
    });

    test('parses Firestore timestamp format as fallback', () {
      final map = _baseRepairMap()
        ..['createdAt'] = {'_seconds': 1717228800, '_nanoseconds': 0};
      final repair = Repair.fromArchiveMap(map);
      expect(repair.createdAt,
          DateTime.fromMillisecondsSinceEpoch(1717228800 * 1000));
    });

    test('parses nullable materialsCost when present', () {
      final repair = Repair.fromArchiveMap(_baseRepairMap(materialsCost: 12.5));
      expect(repair.materialsCost, 12.5);
    });

    test('materialsCost is null when absent', () {
      final repair = Repair.fromArchiveMap(_baseRepairMap());
      expect(repair.materialsCost, isNull);
    });

    test('linked buyer contact fields parsed correctly', () {
      final repair = Repair.fromArchiveMap(_baseRepairMap());
      expect(repair.buyerId, 'buyer-1');
      expect(repair.buyerName, 'Alice');
      expect(repair.freeTextContact, isNull);
    });

    test('free-text contact parsed when buyerId absent', () {
      final repair = Repair.fromArchiveMap(_baseRepairMap(
        buyerId: null,
        buyerName: null,
        freeTextContact: 'Bob',
      ));
      expect(repair.buyerId, isNull);
      expect(repair.freeTextContact, 'Bob');
    });

    test('parses RepairStatus correctly', () {
      final repair = Repair.fromArchiveMap(_baseRepairMap());
      expect(repair.status, RepairStatus.done);
    });

    test('defaults to empty string for missing id', () {
      final map = _baseRepairMap()..remove('id');
      final repair = Repair.fromArchiveMap(map);
      expect(repair.id, '');
    });
  });
}
