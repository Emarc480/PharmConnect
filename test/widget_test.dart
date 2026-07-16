// Basic widget tests for PharmConnect.
//
// These deliberately test widgets that don't touch Firebase directly
// (DrugCard just takes a Drug), so they run with plain `flutter test`
// and no emulator/mocking setup. Screens wired to AuthProvider,
// DrugProvider, OrderProvider, or RefillProvider need a Firebase Test
// harness (e.g. the `firebase_auth_mocks` / `fake_cloud_firestore`
// packages) to widget-test in isolation — a good next step once the
// team has time, noted in README.md.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharm_connect/models/drug.dart';
import 'package:pharm_connect/widgets/drug_card.dart';

void main() {
  const inStockDrug = Drug(
    id: '1',
    name: 'Paracetamol 500mg',
    category: 'Pain Relief',
    price: 2000,
    stockQuantity: 50,
    reorderLevel: 10,
  );

  const outOfStockDrug = Drug(
    id: '2',
    name: 'Metronidazole 400mg',
    category: 'Antibiotics',
    price: 6000,
    stockQuantity: 0,
    reorderLevel: 10,
  );

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('DrugCard shows name, formatted price, and stock label',
      (tester) async {
    await tester.pumpWidget(wrap(DrugCard(drug: inStockDrug)));

    expect(find.text('Paracetamol 500mg'), findsOneWidget);
    expect(find.text('UGX 2,000'), findsOneWidget);
    expect(find.text('In Stock'), findsOneWidget);
  });

  testWidgets('DrugCard shows Out of Stock label for zero stock',
      (tester) async {
    await tester.pumpWidget(wrap(DrugCard(drug: outOfStockDrug)));

    expect(find.text('Out of Stock'), findsOneWidget);
  });

  testWidgets('DrugCard calls onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(DrugCard(drug: inStockDrug, onTap: () => tapped = true)),
    );

    await tester.tap(find.byType(DrugCard));
    expect(tapped, isTrue);
  });
}
