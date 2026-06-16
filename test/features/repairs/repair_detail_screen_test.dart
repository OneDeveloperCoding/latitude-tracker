import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/demo/demo_mode.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/repairs/screens/repair_detail_screen.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';

Repair _makeRepair({RepairStatus status = RepairStatus.inProgress}) => Repair(
      id: 'r1',
      buyerId: 'b1',
      buyerName: 'Ana',
      itemDescription: 'Necklace',
      itemCategory: 'Colares',
      problemDescription: 'Broken clasp',
      status: status,
      payment: const SalePayment(
        status: PaymentStatus.unpaid,
        method: PaymentMethod.cash,
      ),
      returnDelivery: const RepairReturnDelivery(
        type: DeliveryType.shipping,
        status: ShipmentStatus.pending,
      ),
      createdAt: DateTime(2026, 1, 1),
    );

ChoiceChip _findChip(WidgetTester tester, String label) => tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(ChoiceChip),
      ),
    );

void main() {
  setUp(() {
    DemoMode.repairRepo.clear();
  });

  tearDown(() {
    DemoMode.active.value = false;
    DemoMode.repairRepo.clear();
  });

  testWidgets('selected chip matches repair.status', (tester) async {
    await DemoMode.repairRepo.createRepair(_makeRepair(status: RepairStatus.inProgress));
    DemoMode.active.value = true;

    await tester.pumpWidget(
      const MaterialApp(home: RepairDetailScreen(repairId: 'r1')),
    );
    await tester.pumpAndSettle();

    expect(_findChip(tester, 'Em curso').selected, isTrue);
    expect(_findChip(tester, 'Devolvido').selected, isFalse);
  });

  testWidgets('demo mode renders chips non-interactive', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await DemoMode.repairRepo.createRepair(_makeRepair(status: RepairStatus.inProgress));
    DemoMode.active.value = true;

    await tester.pumpWidget(
      const MaterialApp(home: RepairDetailScreen(repairId: 'r1')),
    );
    await tester.pumpAndSettle();

    expect(_findChip(tester, 'Devolvido').onSelected, isNull);

    await tester.tap(find.text('Devolvido'));
    await tester.pumpAndSettle();

    expect(_findChip(tester, 'Em curso').selected, isTrue);
    expect(_findChip(tester, 'Devolvido').selected, isFalse);
  });
}
