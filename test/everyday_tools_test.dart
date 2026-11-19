import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/everyday_calculations.dart';
import 'package:simple_calculator/everyday_tools_page.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/util/theme_model.dart';

Future<void> _open(WidgetTester tester, String tool) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => ThemeModel(),
      child: const MaterialApp(
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: EverydayToolsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('Everyday tools'), findsOneWidget);
  expect(find.text('Tip and bill splitter'), findsOneWidget);
  expect(find.text('Unit price comparison'), findsOneWidget);
  await tester.tap(find.text(tool));
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, Finder field, String value) async {
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextField, label);

Finder _productField(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

void main() {
  test('bill percentages round half a cent up and shares sum to the total', () {
    final split = BillSplit(
      bill: EverydayNumber.parse('0.30')!.cents!,
      tipPercent: EverydayNumber.parse('15')!,
      people: BigInt.from(3),
    );

    expect(formatCents(split.tip), '0.05');
    expect(formatCents(split.total), '0.35');
    expect(split.extraPeople, BigInt.two);
    expect(split.baseShare * split.people + split.extraPeople, split.total);
    expect(EverydayNumber.parse('1e-3000000'), isNull);
    expect(EverydayNumber.parse('1.001')!.cents, isNull);
    expect(EverydayNumber.parse('1,000.10')!.cents, BigInt.from(100010));
    expect(EverydayNumber.parse('+3e−1')!.cents, BigInt.from(30));
  });

  test('equivalent package prices compare exactly after unit conversion', () {
    UnitPrice price(String amount, String size, String baseUnits) => UnitPrice(
      price: EverydayNumber.parse(amount)!.cents!,
      size: EverydayNumber.parse(size)!,
      baseUnits: EverydayNumber.parse(baseUnits)!,
    );
    final small = price('6.50', '750', '0.001');
    final large = price('10.40', '1.2', '1');
    expect(small.compareTo(large), 0);
    expect(small.formatted, '8.6667');
    expect(large.formatted, '8.6667');
  });

  testWidgets('splitter shows rounded tip, total and unequal cent shares', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester, 'Tip and bill splitter');
    await _enter(tester, _field('Bill amount'), '100');
    await _enter(tester, _field('Tip (%)'), '18');
    await _enter(tester, _field('Number of people'), '3');

    expect(find.text('18.00'), findsOneWidget);
    expect(find.text('118.00'), findsOneWidget);
    expect(find.text('1 person pays 39.34'), findsOneWidget);
    expect(find.text('2 people pay 39.33'), findsOneWidget);

    await _enter(tester, _field('Number of people'), '0');
    expect(find.text('Enter a positive whole number.'), findsOneWidget);
    expect(find.text('118.00'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unit price compares mass across units and validates package size',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 680));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _open(tester, 'Unit price comparison');
      await _enter(tester, _productField('item-a-price'), '6.50');
      await _enter(tester, _productField('item-a-size'), '750');
      await _enter(tester, _productField('item-b-price'), '9.90');
      await _enter(tester, _productField('item-b-size'), '1.2');

      await tester.tap(find.byKey(const ValueKey('item-b-unit')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kilograms (kg)').last);
      await tester.pumpAndSettle();
      expect(find.text('8.6667 per kg'), findsOneWidget);
      expect(find.text('8.25 per kg'), findsOneWidget);
      expect(find.text('Item B costs less per unit.'), findsOneWidget);

      await _enter(tester, _productField('item-b-price'), '10.40');
      expect(find.text('Both items have the same unit price.'), findsOneWidget);

      await _enter(tester, _productField('item-b-size'), '0');
      expect(find.text('Enter a size greater than zero.'), findsOneWidget);
      expect(find.text('Both items have the same unit price.'), findsNothing);

      await tester.tap(find.text('Count'));
      await tester.pumpAndSettle();
      await _enter(tester, _productField('item-a-size'), '6');
      await _enter(tester, _productField('item-b-size'), '12');
      expect(find.text('1.0833 per item'), findsOneWidget);
      expect(find.text('0.8667 per item'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
