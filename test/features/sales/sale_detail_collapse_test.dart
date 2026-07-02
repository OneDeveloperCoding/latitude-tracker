import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/services/sale_detail_collapse.dart';

import '../../helpers/sale_factory.dart';

void main() {
  group('deriveInitialSectionCollapse', () {
    test('all sections collapse when payment paid, items ready, delivered', () {
      final sale = makeSale(shipmentStatus: ShipmentStatus.delivered);

      final collapse = sale.deriveInitialSectionCollapse();

      expect(collapse.payment, isTrue);
      expect(collapse.items, isTrue);
      expect(collapse.delivery, isTrue);
    });

    test('all sections stay expanded when nothing is done', () {
      final sale = makeSale(
        assembly: AssemblyStatus.notStarted,
        payment: PaymentStatus.unpaid,
      );

      final collapse = sale.deriveInitialSectionCollapse();

      expect(collapse.payment, isFalse);
      expect(collapse.items, isFalse);
      expect(collapse.delivery, isFalse);
    });

    test('payment collapses independently of the other two sections', () {
      final sale = makeSale(
        assembly: AssemblyStatus.notStarted,
      );

      final collapse = sale.deriveInitialSectionCollapse();

      expect(collapse.payment, isTrue);
      expect(collapse.items, isFalse);
      expect(collapse.delivery, isFalse);
    });

    test('items collapses only when every SaleItem is ready', () {
      final sale = makeSale(
        payment: PaymentStatus.unpaid,
        items: [
          makeSaleItem(id: 'i1'),
          makeSaleItem(id: 'i2', assembly: AssemblyStatus.inProgress),
        ],
      );

      final collapse = sale.deriveInitialSectionCollapse();

      expect(collapse.items, isFalse);
    });

    test('shipped (not yet delivered) shipment keeps Delivery expanded', () {
      final sale = makeSale(
        payment: PaymentStatus.unpaid,
        shipmentStatus: ShipmentStatus.shipped,
      );

      final collapse = sale.deriveInitialSectionCollapse();

      expect(collapse.delivery, isFalse);
    });
  });
}
