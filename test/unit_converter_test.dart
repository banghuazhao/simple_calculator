import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/display.dart';
import 'package:simple_calculator/main.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';

Future<void> _openConverter(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Everyday tools'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, 'Unit converter'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('conversion, swap, result reuse, and undo on a phone', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
    await tester.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const CalculatorApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('C'));
    await tester.tap(find.text('7'));
    await tester.pumpAndSettle();

    await _openConverter(tester);
    await tester.tap(find.text('Temperature'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '-40');
    await tester.pumpAndSettle();
    expect(find.text('-40 °F'), findsOneWidget);

    await tester.tap(find.byTooltip('Swap units'));
    await tester.pumpAndSettle();
    expect(find.text('-40 °C'), findsOneWidget);
    expect(find.text('Fahrenheit (°F)'), findsOneWidget);

    final useResult = find.byWidgetPredicate((widget) => widget is FilledButton);
    await tester.ensureVisible(useResult);
    await tester.tap(useResult);
    await tester.pumpAndSettle();
    expect(tester.widget<Display>(find.byType(Display)).current, '-40');

    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(tester.widget<Display>(find.byType(Display)).current, '7');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'validates input and converts other unit types in a wide window',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        ThemeModel.kHighContrastEnabled: true,
      });
      await StorageManager.init();
      await tester.binding.setSurfaceSize(const Size(900, 620));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();
      await _openConverter(tester);

      final field = find.byType(TextField);
    final useResult = find.byWidgetPredicate((widget) => widget is FilledButton);
      await tester.enterText(field, '1');
      await tester.pumpAndSettle();
      expect(find.text('3.28083989501312 ft'), findsOneWidget);

      await tester.tap(find.text('Mass'));
      await tester.pumpAndSettle();
      expect(find.text('2.20462262184878 lb'), findsOneWidget);

      await tester.tap(find.text('Volume'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('US gallons (US gal)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Millilitres (mL)').last);
      await tester.pumpAndSettle();
      expect(find.text('1000 mL'), findsOneWidget);

      await tester.enterText(field, 'Infinity');
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid number.'), findsOneWidget);
      await tester.ensureVisible(useResult);
      expect(tester.widget<FilledButton>(useResult).onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
