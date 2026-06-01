import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../buyers/repositories/buyer_repository.dart';
import '../../sales/repositories/sale_repository.dart';

class ArchiveService {
  final _salesRepo = SaleRepository();
  final _buyersRepo = BuyerRepository();

  Future<File> exportYear(int year) async {
    final sales = await _salesRepo.getSalesForYear(year);
    final buyers = await _buyersRepo.getAllBuyers();

    final buyerAddresses = <String, List<Map<String, dynamic>>>{};
    for (final buyer in buyers) {
      final addresses = await _buyersRepo.getAllAddressesForBuyer(buyer.id);
      buyerAddresses[buyer.id] =
          addresses.map((a) => a.toFirestore()).toList();
    }

    final archive = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'year': year,
      'sales': sales.map((s) => s.toFirestore()).toList(),
      'buyers': buyers
          .map((b) => {
                ...b.toFirestore(),
                'id': b.id,
                'addresses': buyerAddresses[b.id] ?? [],
              })
          .toList(),
    };

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/latitude_tracker_$year.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(archive),
    );
    return file;
  }

  static Map<String, dynamic>? parseArchive(String jsonContent) {
    try {
      return jsonDecode(jsonContent) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
