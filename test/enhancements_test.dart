import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/display.dart';
import 'package:simple_calculator/everyday_calculations.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/key_controller.dart' as input;
import 'package:simple_calculator/key_symbol.dart';
import 'package:simple_calculator/main.dart';
import 'package:simple_calculator/premium/programmer_page.dart';
import 'package:simple_calculator/premium/scientific_graph.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/input_settings.dart';
import 'package:simple_calculator/util/measurement_units.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';

void _press(Iterable<KeySymbol> keys) {
  for (final symbol in keys) {
    Processor.process(input.KeyEvent(CalculatorKey(symbol: symbol)));
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
    InputSettings.instance.load();
    Processor.restoreHistory();
    Processor.restoreDraft();
    Processor.restoreMemory();
    Processor.clearHistory();
  });

  group('core calculator enhancements', () {
    test('supports 15-digit input, live preview, redo, and memory', () {
      _press([
        Keys.one,
        Keys.two,
        Keys.three,
        Keys.four,
        Keys.five,
        Keys.six,
        Keys.seven,
        Keys.eight,
        Keys.nine,
        Keys.zero,
        Keys.one,
        Keys.two,
      ]);
      expect(Processor.state.current, '123456789012');

      _press([Keys.clear, Keys.one, Keys.two, Keys.add, Keys.eight]);
      expect(Processor.state.preview, '20');

      Processor.undo();
      expect(Processor.state.current, '12');
      expect(Processor.canRedo, isTrue);
      Processor.redo();
      expect(Processor.state.current, '8');
      expect(Processor.state.preview, '20');

      _press([Keys.equals]);
      expect(Processor.state.current, '20');
      Processor.memoryAdd();
      expect(Processor.memoryValue, 20);
      _press([Keys.five]);
      Processor.memorySubtract();
      expect(Processor.memoryValue, 15);
      _press([Keys.clear]);
      Processor.memoryRecall();
      expect(Processor.state.current, '15');
      Processor.memoryClear();
      expect(Processor.hasMemory, isFalse);
    });

    test('repeat equals works when enabled in settings', () {
      InputSettings.instance.setRepeatEqualsEnabled(true);
      _press([Keys.one, Keys.zero, Keys.add, Keys.five, Keys.equals]);
      expect(Processor.state.current, '15');
      _press([Keys.equals]);
      expect(Processor.state.current, '20');
      _press([Keys.equals]);
      expect(Processor.state.current, '25');
      InputSettings.instance.setRepeatEqualsEnabled(false);
    });

    test('history recall inserts as right operand when operator is pending', () {
      _press([Keys.four, Keys.multiply, Keys.five, Keys.equals]);
      final entry = Processor.historyLog.first;
      _press([Keys.clear, Keys.one, Keys.zero, Keys.zero, Keys.add]);
      Processor.setFromHistory(
        entry.result,
        preciseResult: entry.preciseResult,
        asOperandIfPending: true,
      );
      expect(Processor.state.current, '20');
      expect(Processor.state.preview, '120');
      _press([Keys.equals]);
      expect(Processor.state.current, '120');
    });

    testWidgets('swipe on display backspaces and active operator highlights', (
      tester,
    ) async {
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      Future<void> tapKey(String label) async {
        await tester.tap(
          find.descendant(
            of: find.byType(CalculatorKey),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();
      }

      await tapKey('1');
      await tapKey('2');
      await tapKey('3');
      expect(tester.widget<Display>(find.byType(Display)).current, '123');

      await tester.fling(find.byType(Display), const Offset(-200, 0), 800);
      await tester.pumpAndSettle();
      expect(tester.widget<Display>(find.byType(Display)).current, '12');

      await tapKey('+');
      final addKey = tester.widget<CalculatorKey>(
        find.byWidgetPredicate(
          (w) => w is CalculatorKey && w.symbol == Keys.add,
        ),
      );
      expect(addKey.isActive, isTrue);

      await tapKey('8');
      expect(find.byKey(const ValueKey('display-live-preview')), findsOneWidget);
      expect(find.text('= 20'), findsOneWidget);
    });
  });

  group('everyday calculations & expanded units', () {
    test('discount, margin, date difference, and new unit categories work', () {
      final discount = DiscountCalculation(
        originalPrice: 200,
        discountPercent: 25,
        extraDiscountPercent: 10,
        taxPercent: 10,
      );
      expect(discount.discountedSubtotal, closeTo(135, 1e-9));
      expect(discount.totalSavings, closeTo(65, 1e-9));
      expect(discount.taxAmount, closeTo(13.5, 1e-9));
      expect(discount.finalPrice, closeTo(148.5, 1e-9));

      final change = PercentChangeCalculation(from: 80, to: 100);
      expect(change.difference, 20);
      expect(change.percentChange, closeTo(25, 1e-9));

      final margin = MarginCalculation(cost: 60, sellingPrice: 100);
      expect(margin.profit, 40);
      expect(margin.marginPercent, closeTo(40, 1e-9));
      expect(margin.markupPercent, closeTo(66.6666667, 1e-5));

      final diff = DateDifference(
        start: DateTime(2026, 1, 5), // Monday
        end: DateTime(2026, 1, 12), // Next Monday
      );
      expect(diff.totalDays, 7);
      expect(diff.weeks, 1);
      expect(diff.remainingDays, 0);
      expect(diff.businessDays, 5);

      expect(
        MeasurementUnit.gigabyte.convertTo(
          1,
          MeasurementUnit.megabyte,
          MeasurementQuantity.data,
        ),
        1024,
      );
      expect(
        MeasurementUnit.hectare.convertTo(
          1,
          MeasurementUnit.squareMeter,
          MeasurementQuantity.area,
        ),
        10000,
      );
      expect(
        MeasurementUnit.hour.convertTo(
          2,
          MeasurementUnit.minute,
          MeasurementQuantity.time,
        ),
        120,
      );
      expect(
        MeasurementUnit.kmPerHour.convertTo(
          36,
          MeasurementUnit.metersPerSecond,
          MeasurementQuantity.speed,
        ),
        closeTo(10, 1e-9),
      );
    });
  });

  group('graph intersection, programmer mode, and themes', () {
    test('graph finds intersections and key points', () {
      final f = ScientificGraph.compile('x^2', degrees: true);
      final g = ScientificGraph.compile('2x + 3', degrees: true);
      final interval = GraphInterval.tryCreate(0, 5)!;
      final intersection = f.findIntersection(g, interval);
      expect(intersection.status, GraphRootStatus.found);
      expect(intersection.root!.x, closeTo(3, 1e-8));
      expect(intersection.root!.y, closeTo(9, 1e-8));
      expect(f.yIntercept(interval), 0);
    });

    testWidgets('programmer base converter converts and performs bitwise ops', (
      tester,
    ) async {
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
            home: ProgrammerPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('FF'), findsOneWidget);
      expect(find.text('1111 1111'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'AND'));
      await tester.pumpAndSettle();
      expect(find.text('F'), findsOneWidget);
    });

    test('number formatting, system theme sync, and custom palette work', () {
      InputSettings.instance.setCommaDecimalEnabled(true);
      expect(InputSettings.instance.formatDisplayNumber('1234.56'), '1.234,56');
      InputSettings.instance.setThousandsSeparatorEnabled(false);
      expect(InputSettings.instance.formatDisplayNumber('1234.56'), '1234,56');
      InputSettings.instance.setCommaDecimalEnabled(false);
      InputSettings.instance.setThousandsSeparatorEnabled(true);

      final model = ThemeModel();
      model.setLightThemeIndex(4);
      model.setDarkThemeIndex(8);
      model.setFollowSystemTheme(true);
      model.updatePlatformBrightness(Brightness.dark);
      expect(model.activeThemeIndex, 8);
      model.updatePlatformBrightness(Brightness.light);
      expect(model.activeThemeIndex, 4);

      model.setCustomPalette(
        const CustomThemePalette(
          background: Color(0xff121212),
          button1: Color(0xff2A2A2A),
          button2: Color(0xff3B82F6),
          button3: Color(0xff4B5563),
        ),
      );
      expect(model.useCustomTheme, isTrue);
      expect(model.backgroundColor, const Color(0xff121212));
    });

    test('rubber-duck audit regressions: DST dates, comma paste, unit savings rounding', () {
      // DST spring-forward boundary in Pacific/Auckland (2026-09-27 -> 2026-09-28)
      final dstDiff = DateDifference(
        start: DateTime(2026, 9, 27),
        end: DateTime(2026, 9, 28),
      );
      expect(dstDiff.totalDays, 1);

      // Comma-decimal input parsing when enabled
      InputSettings.instance.setCommaDecimalEnabled(true);
      expect(Processor.parseNumericInput('12,5'), 12.5);
      expect(Processor.parseNumericInput('1.234,56'), 1234.56);
      InputSettings.instance.setCommaDecimalEnabled(false);
      expect(Processor.parseNumericInput('12,5'), isNull);

      // Half-up rounding for percentage savings (2/3 saved -> 66.67%)
      final cheap = UnitPrice(
        price: BigInt.from(100),
        size: EverydayNumber.parse('1')!,
        baseUnits: EverydayNumber.parse('1')!,
      );
      final pricey = UnitPrice(
        price: BigInt.from(300),
        size: EverydayNumber.parse('1')!,
        baseUnits: EverydayNumber.parse('1')!,
      );
      expect(cheap.percentSavingsOver(pricey), 66.67);
    });
  });
}
