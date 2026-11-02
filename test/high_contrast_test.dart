import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/display.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/more_page.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';

class _Preferences extends Fake implements SharedPreferences {
  final values = <String, Object>{};
  final writes = <bool>[];
  Completer<bool>? firstWrite;
  bool failReads = false;
  bool failWrites = false;
  bool declineWrites = false;

  @override
  Object? get(String key) {
    if (failReads) throw StateError('read_unavailable');
    return values[key];
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    writes.add(value);
    if (writes.length == 1 && firstWrite != null) await firstWrite!.future;
    if (failWrites) throw StateError('write_unavailable');
    if (declineWrites) return false;
    values[key] = value;
    return true;
  }
}

List<Color> _palette(ThemeModel model) => [
  model.backgroundColor,
  model.buttonColor1,
  model.buttonColor2,
  model.buttonColor3,
  model.textColor1,
  model.textColor2,
];

double _contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return ((first > second ? first : second) + 0.05) /
      ((first > second ? second : first) + 0.05);
}

Future<void> _load(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  await StorageManager.init();
}

Widget _harness(ThemeModel model, {Locale locale = const Locale('en')}) {
  return ChangeNotifierProvider.value(
    value: model,
    child: Consumer<ThemeModel>(
      builder: (context, theme, _) => MaterialApp(
        theme: theme.accessibilityTheme,
        locale: locale,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          backgroundColor: theme.backgroundColor,
          body: const SingleChildScrollView(
            child: Column(
              children: [
                HighContrastSetting(),
                SizedBox(
                  height: 180,
                  child: Display(current: '123', history: '1 + 2 ='),
                ),
                CalculatorKey(symbol: Keys.add),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => _load({}));

  test('contrast defaults off and invalid stored values are ignored', () async {
    expect(ThemeModel().highContrastEnabled, isFalse);
    expect(ThemeModel().accessibilityTheme, isNull);
    for (final invalid in <Object>['true', 1, -1]) {
      await _load({
        ThemeModel.kThemeColorIndex: 4,
        ThemeModel.kHighContrastEnabled: invalid,
      });
      final theme = ThemeModel();
      expect(theme.highContrastEnabled, isFalse);
      expect(theme.themeColor, 4);
    }
  });

  test(
    'saved contrast restores independently of the selected palette',
    () async {
      await _load({
        ThemeModel.kThemeColorIndex: 14,
        ThemeModel.kHighContrastEnabled: true,
      });
      final theme = ThemeModel();
      expect(theme.highContrastEnabled, isTrue);
      expect(theme.themeColor, 14);
      expect(theme.backgroundColor, Colors.black);
      theme.setHighContrastEnabled(false);
      await theme.pendingHighContrastWrites;
      final reloaded = ThemeModel();
      expect(reloaded.highContrastEnabled, isFalse);
      expect(reloaded.themeColor, 14);
      expect(reloaded.backgroundColor, const Color(0xff81D975));
    },
  );

  test(
    'every selected theme is preserved exactly through contrast mode',
    () async {
      final theme = ThemeModel();
      for (var index = 0; index < 18; index++) {
        theme.switchTheme(index);
        final original = _palette(theme);
        theme.setHighContrastEnabled(true);
        expect(theme.themeColor, index);
        theme.setHighContrastEnabled(false);
        expect(_palette(theme), original, reason: 'Theme $index');
      }
      theme.setHighContrastEnabled(true);
      theme.switchTheme(5);
      expect(theme.backgroundColor, Colors.black);
      theme.setHighContrastEnabled(false);
      expect(theme.themeColor, 5);
      expect(theme.backgroundColor, const Color(0xffF6E9B6));
      await theme.pendingHighContrastWrites;
    },
  );

  test('high contrast meets text and control separation ratios', () async {
    final theme = ThemeModel()..setHighContrastEnabled(true);
    for (final background in [
      theme.backgroundColor,
      theme.buttonColor1,
      theme.buttonColor2,
      theme.buttonColor3,
    ]) {
      expect(_contrast(theme.textColor2, background), greaterThanOrEqualTo(7));
    }
    expect(
      _contrast(theme.secondaryTextColor, theme.backgroundColor),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(theme.mutedTextColor, theme.backgroundColor),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(theme.dividerColor, theme.backgroundColor),
      greaterThanOrEqualTo(3),
    );
    expect(
      _contrast(theme.handleColor, theme.backgroundColor),
      greaterThanOrEqualTo(3),
    );
    final material = theme.accessibilityTheme!;
    expect(material.brightness, Brightness.dark);
    expect(
      _contrast(material.colorScheme.onSurface, material.colorScheme.surface),
      greaterThanOrEqualTo(7),
    );
    await theme.pendingHighContrastWrites;
  });

  test(
    'missing or throwing preference reads preserve a usable default',
    () async {
      await StorageManager.init(
        loadPreferences: () async {
          throw PlatformException(code: 'preferences_unavailable');
        },
      );
      final unavailable = ThemeModel()..setHighContrastEnabled(true);
      expect(unavailable.highContrastEnabled, isTrue);
      await unavailable.pendingHighContrastWrites;
      final preferences = _Preferences()..failReads = true;
      await StorageManager.init(loadPreferences: () async => preferences);
      final theme = ThemeModel();
      expect(theme.highContrastEnabled, isFalse);
      expect(theme.themeColor, 0);
    },
  );

  test(
    'failed or declined writes preserve the current contrast choice',
    () async {
      for (final decline in [false, true]) {
        final preferences = _Preferences()
          ..failWrites = !decline
          ..declineWrites = decline;
        await StorageManager.init(loadPreferences: () async => preferences);
        final theme = ThemeModel()..setHighContrastEnabled(true);
        await theme.pendingHighContrastWrites;
        expect(theme.highContrastEnabled, isTrue);
        expect(theme.backgroundColor, Colors.black);
      }
    },
  );

  test('a delayed old save cannot overwrite the latest choice', () async {
    final pending = Completer<bool>();
    final preferences = _Preferences()..firstWrite = pending;
    await StorageManager.init(loadPreferences: () async => preferences);
    final theme = ThemeModel()..setHighContrastEnabled(true);
    theme.setHighContrastEnabled(false);
    await Future<void>.delayed(Duration.zero);
    expect(preferences.writes, [true]);
    expect(theme.highContrastEnabled, isFalse);
    pending.complete(true);
    await theme.pendingHighContrastWrites;
    expect(preferences.writes, [true, false]);
    expect(preferences.values[ThemeModel.kHighContrastEnabled], isFalse);
    expect(ThemeModel().highContrastEnabled, isFalse);
  });

  testWidgets(
    'the contrast switch immediately updates labels and key borders',
    (tester) async {
      final theme = ThemeModel();
      await tester.pumpWidget(_harness(theme));
      await tester.pumpAndSettle();
      final toggle = find.byKey(const ValueKey('high-contrast-setting'));
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(theme.highContrastEnabled, isTrue);
      expect(
        tester.widget<Text>(find.text('1 + 2 =')).style!.color,
        Colors.white,
      );
      final keyContainer = find.descendant(
        of: find.byType(CalculatorKey),
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.decoration is BoxDecoration,
        ),
      );
      final decoration =
          tester.widget<Container>(keyContainer).decoration! as BoxDecoration;
      expect(decoration.color, theme.buttonColor2);
      expect((decoration.border! as Border).top.color, Colors.white);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(theme.highContrastEnabled, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the contrast switch supports Chinese and large system text', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 3.2;
    await tester.binding.setSurfaceSize(const Size(375, 667));
    final theme = ThemeModel();
    await tester.pumpWidget(_harness(theme, locale: const Locale('zh', 'HK')));
    await tester.pumpAndSettle();
    expect(find.text(S.current.highContrast), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('high-contrast-setting')));
    await tester.pumpAndSettle();
    expect(theme.highContrastEnabled, isTrue);
    expect(find.text(S.current.highContrastDescription), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
