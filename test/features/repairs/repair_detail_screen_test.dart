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
  createdAt: DateTime(2026),
);

ChoiceChip _findChip(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(ChoiceChip),
      ),
    );

void main() {
  setUp(DemoMode.repairRepo.clear);

  tearDown(() {
    DemoMode.active.value = false;
    DemoMode.repairRepo.clear();
  });

  testWidgets('selected chip matches repair.status in read mode',
      (tester) async {
    await DemoMode.repairRepo.createRepair(_makeRepair());
    DemoMode.active.value = true;

    await tester.pumpWidget(
      const MaterialApp(home: RepairDetailScreen(repairId: 'r1')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNWidgets(RepairStatus.values.length));
    expect(_findChip(tester, 'Em progresso').selected, isTrue);
    expect(_findChip(tester, 'Devolvido').selected, isFalse);
  });

  testWidgets('status chips are non-interactive in read mode', (tester) async {
    await DemoMode.repairRepo.createRepair(_makeRepair());
    DemoMode.active.value = true;

    await tester.pumpWidget(
      const MaterialApp(home: RepairDetailScreen(repairId: 'r1')),
    );
    await tester.pumpAndSettle();

    // Read-only-by-default: chips are display only until edit mode is entered.
    expect(_findChip(tester, 'Devolvido').onSelected, isNull);
    expect(_findChip(tester, 'Em progresso').onSelected, isNull);
  });

  testWidgets('edit FAB is visible in read mode', (tester) async {
    await DemoMode.repairRepo.createRepair(_makeRepair());
    DemoMode.active.value = true;

    await tester.pumpWidget(
      const MaterialApp(home: RepairDetailScreen(repairId: 'r1')),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });
}
