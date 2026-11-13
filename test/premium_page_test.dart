import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  testWidgets('Mac restores the shared Premium purchase and stays ad-free', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
    const methods = MethodChannel('simple_calculator/premium');
    const events = MethodChannel('simple_calculator/premium_entitlement');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methods, (call) async {
      return switch (call.method) {
        'currentEntitlement' => false,
        'price' => _FakeStore.price,
        'restore' => 'restored',
        _ => throw MissingPluginException(),
      };
    });
    messenger.setMockMethodCallHandler(events, (call) async => null);
    addTearDown(() {
      messenger.setMockMethodCallHandler(methods, null);
      messenger.setMockMethodCallHandler(events, null);
    });
    final controller = PremiumController();
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.loadProduct();

    expect(controller.isSupported, isTrue);
    expect(controller.isPremium, isFalse);
    expect(controller.allowsAds, isFalse);
    await tester.pumpWidget(CalculatorApp(premiumController: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SwiftSum Premium'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'A one-time purchase unlocks the scientific calculator and reusable formulas.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ad-free calculator'), findsNothing);
    expect(find.text('Buy Premium · ${_FakeStore.price}'), findsOneWidget);
    await tester.tap(find.text('Restore purchases'));
    await tester.pumpAndSettle();

    expect(controller.isPremium, isTrue);
    expect(controller.allowsAds, isFalse);
    expect(find.text('Premium purchase restored.'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Scientific calculator'));
    await tester.pumpAndSettle();
    expect(find.byType(ScientificPage), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(controller.isPremium, isFalse);
    expect(find.byType(ScientificPage), findsNothing);
  }, variant: const TargetPlatformVariant({TargetPlatform.macOS}));

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

    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(const Size(375, 667));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    final premiumScroll = find.descendant(
      of: find.byType(PremiumPage),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(buy, -120, scrollable: premiumScroll);
    await tester.pumpAndSettle();
    expect(buy.hitTestable(), findsOneWidget);
    final restore = find.text('Restore purchases');
    await tester.scrollUntilVisible(restore, 120, scrollable: premiumScroll);
    await tester.pumpAndSettle();
    expect(restore.hitTestable(), findsOneWidget);
    await tester.scrollUntilVisible(
      alternateTotal,
      120,
      scrollable: premiumScroll,
    );
    await tester.pumpAndSettle();
    expect(alternateTotal.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.pumpAndSettle();
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
