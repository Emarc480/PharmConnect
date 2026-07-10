import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pharm_connect/main.dart';
import 'package:pharm_connect/providers/inventory_provider.dart';

void main() {
  testWidgets('shows the staff dashboard wireframe', (WidgetTester tester) async {
    await tester.pumpWidget(const _TestApp());

    expect(find.text('PharmConnect Staff'), findsOneWidget);
    expect(find.text('New Orders'), findsOneWidget);
    expect(find.text('Low Stock'), findsOneWidget);
    expect(find.text('Today\'s Sales'), findsOneWidget);
    expect(find.text('Pending Refills'), findsOneWidget);
  });

  testWidgets('opens the inventory wireframe', (WidgetTester tester) async {
    await tester.pumpWidget(const _TestApp());

    await tester.tap(find.text('Inventory').last);
    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsWidgets);
    expect(find.text('Search inventory...'), findsOneWidget);
    expect(find.text('Panadol 500mg'), findsOneWidget);
    expect(find.text('Ed'), findsWidgets);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InventoryProvider(),
      child: const PharmConnect(),
    );
  }
}
