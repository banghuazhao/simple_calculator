import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/premium/formula_storage.dart';
import 'package:simple_calculator/premium/formulas_page.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';

Widget _harness() => ChangeNotifierProvider(
  create: (_) => ThemeModel(),
  child: const MaterialApp(
    locale: Locale('en'),
    supportedLocales: [Locale('en')],
    localizationsDelegates: [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: FormulasPage(),
  ),
);

Finder _field(String name) => find.byKey(ValueKey('formula-$name'));

String? _result(WidgetTester tester, String scenario) =>
    tester.widget<Text>(_field('$scenario-result')).data;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
  });

  test(
    'formula storage keeps valid entries and rejects malformed data',
    () async {
      final preferences = StorageManager.sharedPreferences!;
      final storage = FormulaStorage(preferences: () => preferences);
      final valid = {
        'name': 'Monthly amount',
        'expression': 'amount / months',
        'baseline': {'amount': 24, 'months': 0},
        'alternate': {'months': 2},
      };
      await preferences.setString(
        FormulaStorage.preferencesKey,
        jsonEncode({
          'version': 1,
          'formulas': [
            {...valid, 'name': '   '},
            {...valid, 'expression': 'amount /'},
            {
              ...valid,
              'alternate': {'unknown': 2},
            },
            {
              ...valid,
              'baseline': {'amount': '24'},
            },
            valid,
          ],
        }),
      );
      final formula = storage.load().single;
      expect(formula.name, 'Monthly amount');
      expect(formula.baseline, {'amount': 24.0, 'months': 0.0});
      expect(formula.alternate, {'months': 2.0});

      expect(await storage.save(List.filled(31, formula)), isFalse);
      expect(storage.load(), hasLength(1));
      expect(await storage.save([formula]), isTrue);
      await preferences.reload();
      expect(storage.load().single.toJson(), formula.toJson());
      final unavailable = FormulaStorage(preferences: () => null);
      expect(await unavailable.save([formula]), isFalse);
      expect(unavailable.load(), isEmpty);

      await preferences.setString(
        FormulaStorage.preferencesKey,
        'a' * (129 * 1024),
      );
      expect(storage.load(), isEmpty);
    },
  );

  testWidgets('compares independently editable scenarios and restores them', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('New formula'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('name'), 'My order total');
    await tester.enterText(_field('expression'), 'price * quantity');
    await tester.pumpAndSettle();

    for (final (name, value) in const [
      ('baseline-price', '12.5'),
      ('baseline-quantity', '4'),
      ('alternate-price', '12.5'),
      ('alternate-quantity', '7'),
    ]) {
      await tester.enterText(_field(name), value);
      await tester.pumpAndSettle();
    }
    expect(_result(tester, 'baseline'), '50');
    expect(_result(tester, 'alternate'), '87.5');
    expect(_result(tester, 'difference'), '37.5');
    expect(
      tester.getTopLeft(_field('baseline-price')).dx,
      lessThan(tester.getTopLeft(_field('alternate-price')).dx),
    );

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(_field('baseline-price')).dy,
      lessThan(tester.getTopLeft(_field('alternate-price')).dy),
    );
    expect(_result(tester, 'alternate'), '87.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('My order total'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await StorageManager.sharedPreferences!.reload();
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    expect(find.text('Discounted price'), findsNothing);
    await tester.tap(find.text('My order total'));
    await tester.pumpAndSettle();
    expect(_result(tester, 'baseline'), '50');
    expect(_result(tester, 'alternate'), '87.5');

    final alternateQuantity = _field('alternate-quantity');
    await tester.ensureVisible(alternateQuantity);
    await tester.enterText(alternateQuantity, '8');
    await tester.pumpAndSettle();
    expect(_result(tester, 'alternate'), '100');
    expect(_result(tester, 'difference'), '50');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(FormulaStorage.instance.load().single.alternate['quantity'], 8);

    await tester.tap(find.byTooltip('Delete formula'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete formula').last);
    await tester.pumpAndSettle();
    expect(FormulaStorage.instance.load(), isEmpty);
    expect(find.text('My order total'), findsNothing);
    expect(find.text('Discounted price'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty formulas open examples that can be collapsed', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final examples = find.text('Formula examples');
    final discount = find.text('Discounted price');
    expect(discount.hitTestable(), findsOneWidget);
    await tester.tap(examples);
    await tester.pumpAndSettle();
    expect(discount, findsNothing);
    await tester.tap(examples);
    await tester.pumpAndSettle();
    expect(discount.hitTestable(), findsOneWidget);
  });

  testWidgets('copies the current valid comparison without saving', (
    tester,
  ) async {
    final copies = <String>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copies.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.binding.setSurfaceSize(const Size(800, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discounted price'));
    await tester.pumpAndSettle();

    final discount = _field('alternate-discount_percent');
    final copy = find.widgetWithText(OutlinedButton, 'Copy comparison');
    await tester.enterText(discount, '');
    await tester.pumpAndSettle();
    expect(copy, findsNothing);
    await tester.enterText(discount, 'invalid');
    await tester.pumpAndSettle();
    expect(copy, findsNothing);

    await tester.enterText(discount, '20');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(copy);
    await tester.tap(copy);
    await tester.pumpAndSettle();

    expect(copies, [
      'Discounted price\n'
          'price × (1 - discount_percent / 100)\n'
          'Baseline: 90\n'
          'Alternate: 80\n'
          'Difference (alternate − baseline): -10',
    ]);
    expect(find.text('Copied'), findsOneWidget);
    expect(FormulaStorage.instance.load(), isEmpty);
  });

  testWidgets('invalid syntax and input keep the current draft editable', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('New formula'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('name'), 'Rate');
    await tester.enterText(_field('expression'), 'amount /');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid expression.'), findsOneWidget);
    expect(FormulaStorage.instance.load(), isEmpty);

    await tester.enterText(_field('expression'), 'amount / months');
    await tester.pumpAndSettle();
    await tester.enterText(_field('baseline-amount'), '24');
    await tester.enterText(_field('baseline-months'), '0');
    await tester.enterText(_field('alternate-amount'), 'invalid');
    await tester.pumpAndSettle();
    expect(_result(tester, 'baseline'), 'Error');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid number.'), findsOneWidget);
    expect(FormulaStorage.instance.load(), isEmpty);

    await tester.enterText(_field('alternate-amount'), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(FormulaStorage.instance.load().single.expression, 'amount / months');
    expect(tester.takeException(), isNull);
  });
}
