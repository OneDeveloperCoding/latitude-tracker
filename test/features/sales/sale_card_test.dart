import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latitude_tracker/features/sales/screens/sale_card.dart';

import '../../helpers/sale_factory.dart';

void main() {
  testWidgets('renders buyer name and total price', (tester) async {
    final sale = makeSale(price: 75);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SaleCard(
            sale: sale,
            buyerNif: null,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test Buyer'), findsOneWidget);
    expect(find.text('€75.00'), findsOneWidget);
  });
}
