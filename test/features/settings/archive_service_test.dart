import 'package:latitude_tracker/features/demo/repositories/in_memory_buyer_repository.dart';
import 'package:latitude_tracker/features/demo/repositories/in_memory_repair_repository.dart';
import 'package:latitude_tracker/features/demo/repositories/in_memory_sale_repository.dart';
import 'package:latitude_tracker/features/settings/services/archive_service.dart';
import 'package:test/test.dart';

Map<String, dynamic> _saleMap({
  String id = 's1',
  String createdAt = '2025-06-01T10:00:00.000',
}) =>
    {
      'id': id,
      'buyerId': 'b1',
      'buyerName': 'Ana',
      'items': <dynamic>[],
      'payment': {'status': 'paid', 'method': 'mbWay'},
      'shipment': {'type': 'shipping', 'status': 'pending'},
      'requiresNif': false,
      'atSubmissionDone': false,
      'createdAt': createdAt,
      'scheduledDate': null,
      'notes': null,
    };

Map<String, dynamic> _repairMap({
  String id = 'r1',
  String createdAt = '2025-06-01T10:00:00.000',
}) =>
    {
      'id': id,
      'buyerId': 'b1',
      'buyerName': 'Ana',
      'freeTextContact': null,
      'linkedSaleId': null,
      'itemDescription': 'Colar',
      'itemCategory': 'Colares',
      'problemDescription': 'Broken clasp',
      'workDone': '',
      'materialsCost': null,
      'status': 'received',
      'payment': {'status': 'unpaid', 'method': 'cash'},
      'returnDelivery': {'type': 'shipping', 'status': 'pending'},
      'photoUrls': <dynamic>[],
      'createdAt': createdAt,
    };

Map<String, dynamic> _buyerMap({
  String id = 'b1',
  String createdAt = '2025-01-01T00:00:00.000',
  List<Map<String, dynamic>> addresses = const [],
}) =>
    {
      'id': id,
      'name': 'Ana',
      'instagramHandle': '@ana',
      'phone': null,
      'nif': null,
      'tags': <dynamic>[],
      'notes': null,
      'createdAt': createdAt,
      'addresses': addresses,
    };

Map<String, dynamic> _addressMap({String id = 'addr1'}) => {
      'id': id,
      'label': 'Casa',
      'street': 'Rua das Flores',
      'houseNumber': '10',
      'fraction': null,
      'notes': null,
      'city': 'Porto',
      'postalCode': '4000-123',
      'country': 'Portugal',
      'isDefault': true,
    };

ArchiveService _service({
  InMemorySaleRepository? sales,
  InMemoryBuyerRepository? buyers,
  InMemoryRepairRepository? repairs,
}) =>
    ArchiveService(
      salesRepo: sales ?? InMemorySaleRepository(),
      buyersRepo: buyers ?? InMemoryBuyerRepository(),
      repairsRepo: repairs ?? InMemoryRepairRepository(),
    );

void main() {
  group('ArchiveService.importArchive — version check', () {
    test('throws FormatException for unsupported version', () {
      final service = ArchiveService();
      expect(
        () => service.importArchive({
          'version': '2.0',
          'sales': <dynamic>[],
          'buyers': <dynamic>[],
        }),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('2.0'),
        )),
      );
    });

    test('throws FormatException when version is missing', () {
      final service = ArchiveService();
      expect(
        () => service.importArchive({
          'sales': <dynamic>[],
          'buyers': <dynamic>[],
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ArchiveService.importArchive — new records are imported', () {
    test('imports a sale and returns correct count', () async {
      final salesRepo = InMemorySaleRepository();
      final service = _service(sales: salesRepo);

      final result = await service.importArchive({
        'version': '1.2',
        'sales': [_saleMap()],
        'repairs': <dynamic>[],
        'buyers': <dynamic>[],
      });

      expect(result.salesImported, 1);
      expect(result.skipped, 0);
      final sales = await salesRepo.getSalesForYear(2025);
      expect(sales, hasLength(1));
      expect(sales.first.id, 's1');
    });

    test('imports a repair and returns correct count', () async {
      final repairsRepo = InMemoryRepairRepository();
      final service = _service(repairs: repairsRepo);

      final result = await service.importArchive({
        'version': '1.2',
        'sales': <dynamic>[],
        'repairs': [_repairMap()],
        'buyers': <dynamic>[],
      });

      expect(result.repairsImported, 1);
      expect(result.skipped, 0);
      final repairs = await repairsRepo.getRepairsForYear(2025);
      expect(repairs, hasLength(1));
      expect(repairs.first.id, 'r1');
    });

    test('imports a buyer with address and returns correct count', () async {
      final buyersRepo = InMemoryBuyerRepository();
      final service = _service(buyers: buyersRepo);

      final result = await service.importArchive({
        'version': '1.2',
        'sales': <dynamic>[],
        'repairs': <dynamic>[],
        'buyers': [_buyerMap(addresses: [_addressMap()])],
      });

      expect(result.buyersImported, 1);
      expect(result.skipped, 0);
      final buyers = await buyersRepo.getAllBuyers();
      expect(buyers, hasLength(1));
      expect(buyers.first.id, 'b1');
      final addresses = await buyersRepo.getAllAddressesForBuyer('b1');
      expect(addresses, hasLength(1));
      expect(addresses.first.id, 'addr1');
    });
  });

  group('ArchiveService.importArchive — existing records are skipped', () {
    test('skips a sale that already exists', () async {
      final salesRepo = InMemorySaleRepository();
      final service = _service(sales: salesRepo);
      final archive = {
        'version': '1.2',
        'sales': [_saleMap()],
        'repairs': <dynamic>[],
        'buyers': <dynamic>[],
      };

      await service.importArchive(archive);
      final result = await service.importArchive(archive);

      expect(result.salesImported, 0);
      expect(result.skipped, 1);
    });

    test('skips a buyer that already exists', () async {
      final buyersRepo = InMemoryBuyerRepository();
      final service = _service(buyers: buyersRepo);
      final archive = {
        'version': '1.2',
        'sales': <dynamic>[],
        'repairs': <dynamic>[],
        'buyers': [_buyerMap()],
      };

      await service.importArchive(archive);
      final result = await service.importArchive(archive);

      expect(result.buyersImported, 0);
      expect(result.skipped, 1);
    });

    test('skips a repair that already exists', () async {
      final repairsRepo = InMemoryRepairRepository();
      final service = _service(repairs: repairsRepo);
      final archive = {
        'version': '1.2',
        'sales': <dynamic>[],
        'repairs': [_repairMap()],
        'buyers': <dynamic>[],
      };

      await service.importArchive(archive);
      final result = await service.importArchive(archive);

      expect(result.repairsImported, 0);
      expect(result.skipped, 1);
    });
  });

  group('ArchiveService.importArchive — mixed archive', () {
    test('counts imported and skipped across all types', () async {
      final salesRepo = InMemorySaleRepository();
      final buyersRepo = InMemoryBuyerRepository();
      final repairsRepo = InMemoryRepairRepository();
      final service = _service(
          sales: salesRepo, buyers: buyersRepo, repairs: repairsRepo);

      final archive = {
        'version': '1.2',
        'sales': [_saleMap(), _saleMap(id: 's2')],
        'repairs': [_repairMap()],
        'buyers': [_buyerMap()],
      };
      await service.importArchive(archive);

      final archiveWithDuplicate = {
        'version': '1.2',
        'sales': [_saleMap(), _saleMap(id: 's3')],
        'repairs': [_repairMap()],
        'buyers': [_buyerMap(id: 'b2')],
      };
      final result = await service.importArchive(archiveWithDuplicate);

      expect(result.salesImported, 1);
      expect(result.repairsImported, 0);
      expect(result.buyersImported, 1);
      expect(result.skipped, 2);
    });
  });

  group('ArchiveService.importArchive — malformed entries are silently skipped', () {
    test('entry without id is skipped and not counted', () async {
      final salesRepo = InMemorySaleRepository();
      final service = _service(sales: salesRepo);

      final result = await service.importArchive({
        'version': '1.2',
        'sales': [
          {'buyerId': 'b1', 'createdAt': '2025-01-01T00:00:00.000'},
        ],
        'repairs': <dynamic>[],
        'buyers': <dynamic>[],
      });

      expect(result.salesImported, 0);
      expect(result.skipped, 0);
    });
  });
}
