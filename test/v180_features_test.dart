import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/currency_converter_page.dart';
import 'package:simple_calculator/display.dart';
import 'package:simple_calculator/everyday_calculations.dart';
import 'package:simple_calculator/everyday_tools_page.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/key_pad.dart';
import 'package:simple_calculator/main.dart';
import 'package:simple_calculator/premium/formula_storage.dart';
import 'package:simple_calculator/premium/scientific_page.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/unit_converter_page.dart';
import 'package:simple_calculator/util/backup_manager.dart';
import 'package:simple_calculator/util/currency_converter.dart';
import 'package:simple_calculator/util/desktop_window_helper.dart';
import 'package:simple_calculator/util/input_settings.dart';
import 'package:simple_calculator/util/quick_actions_service.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';

Widget _wrapPage(Widget child, {ThemeModel? theme}) {
  return ChangeNotifierProvider<ThemeModel>.value(
    value: theme ?? ThemeModel(),
    child: MaterialApp(
      key: UniqueKey(),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
    InputSettings.instance.load();
    CurrencyConverterStore.instance.load();
    Processor.restoreHistory();
    Processor.restoreDraft();
    Processor.restoreMemory();
    Processor.clearHistory();
    Processor.clearAll();
  });

  group('core calculator v1.8.0 UX', () {
    testWidgets(
      'editing first operand does not shift calculator layout when keyboard inset appears',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        await tester.binding.setSurfaceSize(const Size(393, 852));

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

        for (final k in ['1', '2', '+', '8']) {
          await tapKey(k);
        }

        final displayRectBefore = tester.getRect(
          find.byKey(const ValueKey('display-panel')),
        );
        final keypadRectBefore = tester.getRect(find.byType(KeyPad));

        await tester.tap(find.byTooltip('Edit first number'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('correct-operand-dialog')),
          findsOneWidget,
        );

        // Simulate a 300px tall soft keyboard appearing while dialog is open.
        tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
        await tester.pumpAndSettle();

        expect(
          tester.getRect(find.byKey(const ValueKey('display-panel'))),
          displayRectBefore,
        );
        expect(tester.getRect(find.byType(KeyPad)), keypadRectBefore);
        expect(tester.takeException(), isNull);

        tester.view.resetViewInsets();
      },
    );

    testWidgets(
      'toolbar redo button and smart C/AC clear entry vs all clear work',
      (tester) async {
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

        for (final k in ['1', '2', '+', '8']) {
          await tapKey(k);
        }
        expect(tester.widget<Display>(find.byType(Display)).current, '8');

        // Tap C -> clears only the second operand (Clear Entry), switches label to AC.
        await tapKey('C');
        expect(tester.widget<Display>(find.byType(Display)).current, '0');
        expect(tester.widget<Display>(find.byType(Display)).history, '12 +');
        expect(
          find.descendant(
            of: find.byType(CalculatorKey),
            matching: find.text('AC'),
          ),
          findsOneWidget,
        );

        // Enter replacement operand 5 -> 12 + 5 = 17.
        await tapKey('5');
        await tapKey('=');
        expect(tester.widget<Display>(find.byType(Display)).current, '17');

        // Undo and then tap toolbar Redo button.
        await tester.tap(find.byTooltip('Undo'));
        await tester.pumpAndSettle();
        expect(tester.widget<Display>(find.byType(Display)).current, '5');

        await tester.tap(find.byKey(const ValueKey('toolbar-redo-button')));
        await tester.pumpAndSettle();
        expect(tester.widget<Display>(find.byType(Display)).current, '17');

        // Long-press C during second operand clears everything immediately.
        await tapKey('C');
        for (final k in ['9', '+', '4']) {
          await tapKey(k);
        }
        await tester.longPress(
          find.descendant(
            of: find.byType(CalculatorKey),
            matching: find.text('C'),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<Display>(find.byType(Display)).current, '0');
        expect(tester.widget<Display>(find.byType(Display)).history, isEmpty);
      },
    );

    testWidgets(
      'scientific page live preview slot keeps fixed height without shifting chips',
      (tester) async {
        await tester.pumpWidget(_wrapPage(const ScientificPage()));
        await tester.pumpAndSettle();

        final slotFinder = find.byKey(
          const ValueKey('scientific-live-preview-slot'),
        );
        final degreesChip = find.widgetWithText(ChoiceChip, 'Degrees');
        final initialSlotRect = tester.getRect(slotFinder);
        final initialChipTop = tester.getTopLeft(degreesChip).dy;

        await tester.enterText(find.byType(TextField), '2 * 15');
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('scientific-live-preview')),
          findsOneWidget,
        );
        expect(find.text('= 30'), findsOneWidget);
        expect(tester.getRect(slotFinder), initialSlotRect);
        expect(tester.getTopLeft(degreesChip).dy, initialChipTop);
      },
    );
  });

  group('loan, compound, currency, and unit presets', () {
    test('loan and compound interest formulas compute accurately', () {
      final loan = LoanCalculation(
        principal: 100000,
        annualRatePercent: 6,
        termYears: 30,
      );
      expect(loan.monthlyPayment, closeTo(599.55, 0.01));
      expect(loan.totalInterest, closeTo(115838.19, 0.5));

      final zeroLoan = LoanCalculation(
        principal: 12000,
        annualRatePercent: 0,
        termYears: 2,
      );
      expect(zeroLoan.monthlyPayment, closeTo(500, 1e-9));
      expect(zeroLoan.totalInterest, 0);

      final compound = CompoundInterestCalculation(
        principal: 10000,
        monthlyContribution: 0,
        annualRatePercent: 5,
        years: 10,
        frequency: CompoundFrequency.yearly,
      );
      expect(compound.finalBalance, closeTo(16288.95, 0.01));
      expect(compound.interestEarned, closeTo(6288.95, 0.01));
    });

    test('currency converter works offline, supports custom rate and online refresh', () async {
      final store = CurrencyConverterStore.instance;
      expect(store.convert(100, 'USD', 'EUR'), closeTo(92.0, 0.01));

      store.setCustomRate('USD', 'EUR', 0.95);
      expect(store.hasCustomRate('USD', 'EUR'), isTrue);
      expect(store.convert(100, 'USD', 'EUR'), closeTo(95.0, 0.001));

      store.clearCustomRate('USD', 'EUR');
      expect(store.hasCustomRate('USD', 'EUR'), isFalse);

      final ok = await store.refreshOnline(
        fetcher: () async => {'USD': 1.0, 'EUR': 0.91, 'JPY': 150.0},
      );
      expect(ok, isTrue);
      expect(store.updatedAtIso, isNotNull);
      expect(store.convert(100, 'USD', 'EUR'), closeTo(91.0, 0.001));

      final failed = await store.refreshOnline(fetcher: () async => null);
      expect(failed, isFalse);
      expect(store.convert(100, 'USD', 'EUR'), closeTo(91.0, 0.001));
    });

    testWidgets('loan & compound and currency converter pages render and calculate', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapPage(const EverydayToolsPage()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Loan and interest'), 200);
      await tester.tap(find.text('Loan and interest'));
      await tester.pumpAndSettle();
      expect(find.text('Monthly payment'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Compound'));
      await tester.pumpAndSettle();
      expect(find.text('Final balance'), findsOneWidget);

      await tester.pumpWidget(_wrapPage(const CurrencyConverterPage()));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('currency-result-text')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('currency-custom-rate')),
        '2',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('200.00'), findsOneWidget);
    });

    testWidgets('unit converter quick presets and pin toggle persist', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapPage(const UnitConverterPage()));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('converter-pinned-pairs')),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(ActionChip, '°C → °F'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '100');
      await tester.pumpAndSettle();
      expect(find.text('212 °F'), findsOneWidget);

      // Pin m -> ft by switching back to Length (default m -> ft) and pinning.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Length'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('converter-pin-button')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, 'm → ft'), findsOneWidget);
    });
  });

  group('backup, quick actions, and macOS window pin', () {
    test('backup manager exports, restores, and rejects invalid JSON atomically', () async {
      final theme = ThemeModel();
      theme.switchTheme(5);
      InputSettings.instance.setMemoryBarEnabled(true);
      await FormulaStorage.instance.save([
        SavedFormula(
          name: 'Tax',
          expression: 'price * 1.15',
          baseline: const {'price': 100},
          alternate: const {'price': 200},
        ),
      ]);

      final exported = BackupManager.exportJson(theme);
      final decoded = jsonDecode(exported) as Map<String, dynamic>;
      expect(decoded['app'], 'SwiftSum');
      expect(decoded['version'], 1);

      // Mutate state and then restore from backup.
      theme.switchTheme(0);
      InputSettings.instance.setMemoryBarEnabled(false);
      await FormulaStorage.instance.save([]);

      final invalidResult = await BackupManager.importJson(
        '{"not": "valid"}',
        theme,
      );
      expect(invalidResult, isFalse);
      expect(theme.themeColor, 0);

      final restored = await BackupManager.importJson(exported, theme);
      expect(restored, isTrue);
      expect(theme.themeColor, 5);
      expect(InputSettings.instance.memoryBarEnabled, isTrue);
      expect(FormulaStorage.instance.load().single.name, 'Tax');
    });

    testWidgets('quick action routes directly to unit converter', (
      tester,
    ) async {
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      QuickActionsService.instance.dispatch(
        QuickActionsService.actionUnitConverter,
      );
      await tester.pumpAndSettle();
      expect(find.byType(UnitConverterPage), findsOneWidget);
    });

    test('desktop window helper persists always-on-top preference', () async {
      final calls = <bool>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel(DesktopWindowHelper.channelName),
            (call) async {
              if (call.method == 'setAlwaysOnTop') {
                calls.add(call.arguments as bool);
                return call.arguments as bool;
              }
              return null;
            },
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel(DesktopWindowHelper.channelName),
              null,
            ),
      );

      await DesktopWindowHelper.instance.loadAndApply();
      expect(DesktopWindowHelper.instance.alwaysOnTop, isFalse);

      await DesktopWindowHelper.instance.setAlwaysOnTop(true);
      expect(DesktopWindowHelper.instance.alwaysOnTop, isTrue);
      expect(
        StorageManager.sharedPreferences?.getBool(
          DesktopWindowHelper.alwaysOnTopKey,
        ),
        isTrue,
      );
    });
  });
}
