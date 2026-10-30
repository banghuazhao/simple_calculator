import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/display.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/main.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'toolbar undo, translated history, and accessible layout work together',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await StorageManager.init();
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.binding.setSurfaceSize(const Size(375, 667));
      tester.platformDispatcher.localesTestValue = [const Locale('en')];
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      Finder keypadText(String symbol) => find.descendant(
        of: find.byType(CalculatorKey),
        matching: find.text(symbol),
      );

      Future<void> press(String symbol) async {
        await tester.tap(keypadText(symbol));
        await tester.pumpAndSettle();
      }

      String current() => tester.widget<Display>(find.byType(Display)).current;

      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo))
            .onPressed,
        isNull,
      );
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.byTooltip('History'), findsOneWidget);

      for (final symbol in ['1', '+', '2', '=']) {
        await press(symbol);
      }
      expect(current(), '3');
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(current(), '2');
      await press('C');
      expect(current(), '0');
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(current(), '2');

      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(Dismissible), matching: find.text('3')),
      );
      await tester.pumpAndSettle();
      expect(current(), '3');
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(current(), '2');
      while (Processor.canUndo) {
        await tester.tap(find.byTooltip('Undo'));
        await tester.pumpAndSettle();
      }
      expect(current(), '0');
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo))
            .onPressed,
        isNull,
      );

      // Changing the system language should select the correct Chinese script,
      // including regional locales that do not provide an explicit script code.
      final languages = <Locale, List<String>>{
        const Locale('en'): ['History', 'Undo'],
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'): [
          '历史记录',
          '撤销',
        ],
        const Locale('zh', 'HK'): ['歷史記錄', '復原'],
        const Locale('zh', 'TW'): ['歷史記錄', '復原'],
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'): [
          '歷史記錄',
          '復原',
        ],
      };
      for (final language in languages.entries) {
        tester.platformDispatcher.localesTestValue = [language.key];
        await tester.pumpAndSettle();
        final strings = S.current;
        expect(find.byTooltip(language.value[1]), findsOneWidget);
        await press('C');
        for (final symbol in ['1', '+', '2', '=']) {
          await press(symbol);
        }
        await tester.tap(find.byTooltip(language.value[0]));
        await tester.pumpAndSettle();
        expect(find.text(language.value[0]), findsOneWidget);
        await tester.tap(find.text(strings.clear));
        await tester.pumpAndSettle();
        expect(find.text(strings.clearHistoryTitle), findsOneWidget);
        expect(find.text(strings.clearHistoryMessage), findsOneWidget);
        await tester.tap(find.text(strings.cancel));
        await tester.pumpAndSettle();
        expect(Processor.historyLog, isNotEmpty);
        await tester.tap(find.text(strings.clear));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(strings.clear),
          ),
        );
        await tester.pumpAndSettle();
        expect(Processor.historyLog, isEmpty);
        expect(find.text(strings.noCalculationsYet), findsOneWidget);
        expect(current(), '3');
        Navigator.of(
          tester.element(find.text(strings.noCalculationsYet)),
        ).pop();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      // Check the extra toolbar button and translated sheet at large text sizes,
      // on a small phone and a landscape tablet, using light and dark themes.
      final context = tester.element(find.byType(Display));
      final theme = Provider.of<ThemeModel>(context, listen: false);
      for (final themeIndex in [0, 8]) {
        theme.switchTheme(themeIndex);
        tester.platformDispatcher.textScaleFactorTestValue = 3.2;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        for (final size in [const Size(375, 667), const Size(800, 600)]) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester.getBottomRight(keypadText('=')).dy,
            lessThan(size.height),
          );
          await tester.tap(find.byTooltip(S.current.history));
          await tester.pumpAndSettle();
          expect(find.text(S.current.noCalculationsYet), findsOneWidget);
          expect(tester.takeException(), isNull);
          Navigator.of(
            tester.element(find.text(S.current.noCalculationsYet)),
          ).pop();
          await tester.pumpAndSettle();

          for (final symbol in ['C', '1', '+', '2', '=']) {
            await press(symbol);
          }
          await tester.tap(find.byTooltip(S.current.history));
          await tester.pumpAndSettle();
          await tester.tap(find.text(S.current.clear));
          await tester.pumpAndSettle();
          expect(find.text(S.current.clearHistoryTitle), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text(S.current.clear),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text(S.current.noCalculationsYet), findsOneWidget);
          Navigator.of(
            tester.element(find.text(S.current.noCalculationsYet)),
          ).pop();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}
