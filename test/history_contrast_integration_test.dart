import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/calculator.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/display.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/history_sheet.dart';
import 'package:simple_calculator/main.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/input_settings.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';

void main() {
  testWidgets(
    'high contrast and bulk copy work together without changing input',
    (tester) async {
      SharedPreferences.setMockInitialValues({ThemeModel.kThemeColorIndex: 9});
      await StorageManager.init();
      InputSettings.instance.load();
      Processor.restoreHistory();
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.binding.setSurfaceSize(const Size(375, 667));
      tester.platformDispatcher.localesTestValue = [const Locale('en')];
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      final model = Provider.of<ThemeModel>(
        tester.element(find.byType(Calculator)),
        listen: false,
      );
      final originalColors = [
        model.backgroundColor,
        model.textColor1,
        model.textColor2,
        model.buttonColor1,
        model.buttonColor2,
        model.buttonColor3,
      ];
      Finder keyText(String symbol) => find.descendant(
        of: find.byType(CalculatorKey),
        matching: find.text(symbol),
      );
      Future<void> press(String symbol) async {
        await tester.tap(keyText(symbol));
        await tester.pumpAndSettle();
      }

      String current() => tester
          .widget<Display>(find.byType(Display, skipOffstage: false))
          .current;
      for (final symbol in ['1', '+', '2', '=', '4', '×', '5', '=']) {
        await press(symbol);
      }
      final historyIds = Processor.historyLog.map((entry) => entry.id).toList();
      expect(current(), '20');

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      final toggle = find.byKey(const ValueKey('high-contrast-setting'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(model.highContrastEnabled, isTrue);
      expect(model.themeColor, 9);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!.brightness,
        Brightness.dark,
      );
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(current(), '20');
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        model.backgroundColor,
      );

      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();
      final equation = find.descendant(
        of: find.byType(HistorySheet),
        matching: find.text('4 × 5 ='),
      );
      expect(
        tester.widget<Text>(equation).style!.color,
        model.secondaryTextColor,
      );
      await tester.tap(find.byTooltip(S.current.copyAllHistory));
      await tester.pumpAndSettle();
      expect(copied, ['4 × 5 = 20\n1 + 2 = 3']);
      await tester.enterText(find.byKey(const ValueKey('history-search')), '*');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(S.current.copyMatchingHistory));
      await tester.pumpAndSettle();
      expect(copied.last, '4 × 5 = 20');
      expect(Processor.historyLog.map((entry) => entry.id), historyIds);
      expect(current(), '20');

      // Keep both actions usable with large text, a narrow phone, and landscape.
      tester.platformDispatcher.textScaleFactorTestValue = 3.2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      for (final size in [const Size(320, 568), const Size(800, 600)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final copyButton = find.byKey(const ValueKey('history-copy-bulk'));
        await tester.ensureVisible(copyButton);
        await tester.pumpAndSettle();
        expect(tester.getSize(copyButton).width, greaterThanOrEqualTo(44));
        expect(tester.getSize(copyButton).height, greaterThanOrEqualTo(44));
        await tester.tap(copyButton);
        await tester.pumpAndSettle();
        expect(copied.last, '4 × 5 = 20');
        expect(tester.takeException(), isNull);
      }

      model.setHighContrastEnabled(false);
      await tester.pumpAndSettle();
      expect(model.themeColor, 9);
      expect([
        model.backgroundColor,
        model.textColor1,
        model.textColor2,
        model.buttonColor1,
        model.buttonColor2,
        model.buttonColor3,
      ], originalColors);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).theme,
        isNull,
      );
      expect(
        tester.widget<Text>(equation).style!.color,
        model.secondaryTextColor,
      );
      Navigator.of(tester.element(find.byType(HistorySheet))).pop();
      await tester.pumpAndSettle();
      expect(current(), '20');
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(current(), '5');
      expect(tester.takeException(), isNull);
    },
  );
}
