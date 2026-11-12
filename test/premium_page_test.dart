import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/main.dart';
import 'package:simple_calculator/premium/formula_storage.dart';
import 'package:simple_calculator/premium/formulas_page.dart';
import 'package:simple_calculator/premium/premium_controller.dart';
import 'package:simple_calculator/premium/premium_page.dart';
import 'package:simple_calculator/premium/scientific_page.dart';
import 'package:simple_calculator/util/storage_manager.dart';

class _FakeStore implements PremiumStore {
  static const price = '9,99\u00a0€';
  final updates = StreamController<bool>.broadcast();

  @override
  Stream<bool> get entitlementUpdates => updates.stream;

  @override
  Future<bool> currentEntitlement() async => false;

  @override
  Future<String?> loadPrice() async => price;

  @override
  Future<PremiumOutcome> purchase() async => PremiumOutcome.purchased;

  @override
  Future<PremiumOutcome> restore() async => PremiumOutcome.notPurchased;
}

void main() {
  testWidgets('Premium purchase unlocks tools until entitlement is revoked', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
    final store = _FakeStore();
    final controller = PremiumController(store: store, supported: true);
    addTearDown(() async {
      controller.dispose();
      await store.updates.close();
    });
    await controller.initialize();
    await controller.loadProduct();

    await tester.pumpWidget(CalculatorApp(premiumController: controller));
    await tester.pumpAndSettle();
    final premiumTools = find.byTooltip('Premium tools');
    expect(premiumTools, findsNothing);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SwiftSum Premium'));
    await tester.pumpAndSettle();

    final scientific = find.widgetWithText(ListTile, 'Scientific calculator');
    final formulas = find.widgetWithText(ListTile, 'Reusable formulas');
    final buy = find.text('Buy Premium · ${_FakeStore.price}');
    final preview = find.text('What-if preview');
    final alternateTotal = find.text(r'With 25% off, you pay $75.');
    expect(tester.widget<ListTile>(scientific).onTap, isNull);
    expect(tester.widget<ListTile>(formulas).onTap, isNull);
    expect(controller.allowsAds, isTrue);
    await tester.scrollUntilVisible(alternateTotal, 120);
    await tester.pumpAndSettle();
    expect(preview, findsOneWidget);
    expect(find.text(r'With 10% off, you pay $90.'), findsOneWidget);
    expect(alternateTotal, findsOneWidget);
    expect(find.byType(EditableText), findsNothing);

    await tester.ensureVisible(buy);
    await tester.pumpAndSettle();
    await tester.tap(buy);
    await tester.pumpAndSettle();
    expect(find.text('Premium is active.'), findsOneWidget);
    expect(buy, findsNothing);
    expect(preview, findsNothing);
    expect(controller.isPremium, isTrue);
    expect(controller.allowsAds, isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(premiumTools);
    await tester.pumpAndSettle();
    expect(find.byType(PremiumPage), findsOneWidget);
    expect(tester.widget<ListTile>(scientific).onTap, isNotNull);
    expect(tester.widget<ListTile>(formulas).onTap, isNotNull);

    await tester.tap(scientific);
    await tester.pumpAndSettle();
    expect(find.byType(ScientificPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(formulas);
    await tester.pumpAndSettle();
    expect(find.byType(FormulasPage), findsOneWidget);
    await tester.tap(find.text('New formula'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('formula-name')), 'Draft');
    await tester.enterText(
      find.byKey(const ValueKey('formula-expression')),
      '2+2',
    );
    await tester.pumpAndSettle();

    store.updates.add(false);
    // An already visible Save button must respect a revocation received before
    // Flutter has rendered the updated route.
    await tester.idle();
    expect(controller.isPremium, isFalse);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('formula-name')), findsNothing);
    expect(find.byType(FormulasPage), findsNothing);
    expect(find.byType(PremiumPage), findsOneWidget);
    expect(tester.widget<ListTile>(formulas).onTap, isNull);
    expect(FormulaStorage.instance.load(), isEmpty);
    expect(controller.allowsAds, isTrue);
    Navigator.of(
      tester.element(find.byType(PremiumPage)),
    ).popUntil((route) => route.isFirst);
    await tester.pumpAndSettle();
    expect(premiumTools, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
