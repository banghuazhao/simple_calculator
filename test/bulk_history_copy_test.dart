import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/history_sheet.dart';
import 'package:simple_calculator/key_controller.dart' as input;
import 'package:simple_calculator/key_symbol.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/history_storage.dart';
import 'package:simple_calculator/util/input_settings.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';

const _bulkKey = ValueKey('history-copy-bulk');
const _allHistory = '8 ÷ 2 = 4\n4 × 5 = 20\n1 + 2 = 3';

Widget _harness({Locale locale = const Locale('en')}) {
  return ChangeNotifierProvider(
    create: (_) => ThemeModel(),
    child: MaterialApp(
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const HistorySheet(),
            ),
            child: const Text('Open history'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(_harness(locale: locale));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open history'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CalcState state;
  late StreamSubscription<CalcState> subscription;

  void press(List<KeySymbol> symbols) {
    for (final symbol in symbols) {
      Processor.process(input.KeyEvent(CalculatorKey(symbol: symbol)));
    }
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({InputSettings.hapticsKey: false});
    await StorageManager.init();
    InputSettings.instance.load();
    Processor.restoreHistory();
    subscription = Processor.listen((value) => state = value);
    press([Keys.clear, Keys.one, Keys.add, Keys.two, Keys.equals]);
    press([Keys.clear, Keys.four, Keys.multiply, Keys.five, Keys.equals]);
    press([Keys.clear, Keys.eight, Keys.divide, Keys.two, Keys.equals]);
    Processor.setFromHistory('77');
    await Future<void>.delayed(Duration.zero);
    await HistoryStorage.instance.flush();
  });

  tearDown(() async {
    while (Processor.canUndo) {
      Processor.undo();
    }
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();
  });

  void mockClipboard(
    WidgetTester tester,
    Future<Object?> Function(MethodCall) handler,
  ) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      handler,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  testWidgets('bulk copy preserves exact newest-first data, input, and undo', (
    tester,
  ) async {
    final copies = <String>[];
    mockClipboard(tester, (call) async {
      if (call.method == 'Clipboard.setData') {
        copies.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    final before = StorageManager.sharedPreferences!.getString(
      HistoryStorage.preferencesKey,
    );
    final ids = Processor.historyLog.map((entry) => entry.id).toList();
    await _open(tester);

    expect(find.byTooltip('Copy all history'), findsOneWidget);
    await tester.tap(find.byKey(_bulkKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_bulkKey));
    await tester.pumpAndSettle();

    expect(copies, [_allHistory, _allHistory]);
    expect(find.text('Copied'), findsOneWidget);
    expect(state.current, '77');
    expect(Processor.historyLog.map((entry) => entry.id), ids);
    expect(
      StorageManager.sharedPreferences!.getString(
        HistoryStorage.preferencesKey,
      ),
      before,
    );
    Processor.undo();
    await tester.pumpAndSettle();
    expect(state.current, '4');
    expect(state.history, '8 ÷ 2 =');
    expect(state.isResult, isTrue);
  });

  testWidgets('bulk copy follows result and operator-alias search filters', (
    tester,
  ) async {
    final copies = <String>[];
    mockClipboard(tester, (call) async {
      if (call.method == 'Clipboard.setData') {
        copies.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    await _open(tester);
    final search = find.byKey(const ValueKey('history-search'));
    await tester.enterText(search, '4*5');
    await tester.pumpAndSettle();
    expect(find.byTooltip(S.current.copyMatchingHistory), findsOneWidget);
    await tester.tap(find.byKey(_bulkKey));
    await tester.pumpAndSettle();
    await tester.enterText(search, '2');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_bulkKey));
    await tester.pumpAndSettle();
    await tester.enterText(search, '8/2');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_bulkKey));
    await tester.pumpAndSettle();
    expect(copies, ['4 × 5 = 20', _allHistory, '8 ÷ 2 = 4']);
    expect(Processor.historyLog, hasLength(3));
    expect(state.current, '77');
  });

  testWidgets('history finds grouped numbers and copies the original text', (
    tester,
  ) async {
    final copies = <String>[];
    mockClipboard(tester, (call) async {
      if (call.method == 'Clipboard.setData') {
        copies.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    Processor.setFromHistory('-1234567.5');
    press([Keys.divide]);
    expect(Processor.paste('1000'), isTrue);
    press([Keys.equals]);
    Processor.setFromHistory('77');
    final history = Processor.historyLog;
    await _open(tester);

    final search = find.byKey(const ValueKey('history-search'));
    const equation = '-1234567.5 ÷ 1000 =';
    for (final query in ['-1234.5675', '−1,234.5675', '−1,234,567.5 / 1,000']) {
      await tester.enterText(search, query);
      await tester.pumpAndSettle();
      expect(find.text(equation), findsOneWidget, reason: query);
      expect(find.text('8 ÷ 2 ='), findsNothing, reason: query);
    }

    await tester.tap(find.byTooltip(S.current.copyMatchingHistory));
    await tester.pumpAndSettle();
    expect(copies, ['$equation -1234.5675']);

    for (final query in ['−12,34.5675', '−1,234.5,675', ',']) {
      await tester.enterText(search, query);
      await tester.pumpAndSettle();
      expect(
        find.text(S.current.noHistoryMatches),
        findsOneWidget,
        reason: query,
      );
      expect(tester.widget<IconButton>(find.byKey(_bulkKey)).onPressed, isNull);
    }
    expect(Processor.historyLog, history);
    expect(state.current, '77');
  });

  testWidgets('history actions delete a filtered row and Undo restores order', (
    tester,
  ) async {
    final history = Processor.historyLog;
    await _open(tester);
    final strings = S.current;
    final search = find.byKey(const ValueKey('history-search'));
    const equation = '4 × 5 =';
    await tester.enterText(search, '4*5');
    await tester.pumpAndSettle();

    void semanticTap(Finder finder, {String? value, String? tooltip}) {
      final node = tester.getSemantics(finder);
      expect(
        node,
        isSemantics(value: value, tooltip: tooltip, hasTapAction: true),
      );
      node.owner!.performAction(node.id, SemanticsAction.tap);
    }

    expect(find.byTooltip(strings.copyCalculation), findsOneWidget);
    semanticTap(
      find.byTooltip(strings.historyEntryActions),
      value: equation,
      tooltip: strings.historyEntryActions,
    );
    await tester.pumpAndSettle();
    semanticTap(find.text(strings.deleteCalculation));
    await tester.pumpAndSettle();

    expect(find.text(equation), findsNothing);
    expect(find.text(strings.noHistoryMatches), findsOneWidget);
    expect(Processor.historyLog, [history[0], history[2]]);

    semanticTap(find.text(strings.undo));
    await tester.pumpAndSettle();
    expect(find.text(equation), findsOneWidget);
    expect(find.text('8 ÷ 2 ='), findsNothing);
    expect(Processor.historyLog, history);
    expect(state.current, '77');
  });

  testWidgets('empty history and no matches disable bulk copying', (
    tester,
  ) async {
    var writes = 0;
    mockClipboard(tester, (call) async {
      if (call.method == 'Clipboard.setData') writes++;
      return null;
    });
    await _open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('history-search')),
      'not a calculation',
    );
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(find.byKey(_bulkKey)).onPressed, isNull);
    expect(find.byTooltip(S.current.copyMatchingHistory), findsOneWidget);
    await tester.tap(find.byKey(_bulkKey));
    await tester.pumpAndSettle();
    expect(writes, 0);

    Navigator.of(tester.element(find.byType(HistorySheet))).pop();
    await tester.pumpAndSettle();
    Processor.clearHistory();
    await tester.tap(find.text('Open history'));
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(find.byKey(_bulkKey)).onPressed, isNull);
    expect(find.byTooltip('Copy all history'), findsOneWidget);
    await tester.tap(find.byKey(_bulkKey));
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(find.text('Copied'), findsNothing);
  });

  testWidgets('clipboard failure has no false success or history mutation', (
    tester,
  ) async {
    mockClipboard(tester, (call) async {
      if (call.method == 'Clipboard.setData') {
        throw PlatformException(code: 'clipboard_unavailable');
      }
      return null;
    });
    await _open(tester);
    final ids = Processor.historyLog.map((entry) => entry.id).toList();
    await tester.tap(find.byKey(_bulkKey));
    await tester.pumpAndSettle();
    expect(find.text('Copied'), findsNothing);
    expect(Processor.historyLog.map((entry) => entry.id), ids);
    expect(state.current, '77');
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing the sheet during bulk copying is safe', (tester) async {
    final pending = Completer<void>();
    final copies = <String>[];
    mockClipboard(tester, (call) async {
      if (call.method == 'Clipboard.setData') {
        copies.add((call.arguments as Map)['text'] as String);
        await pending.future;
      }
      return null;
    });
    await _open(tester);
    await tester.tap(find.byKey(_bulkKey));
    await tester.pump();
    Navigator.of(tester.element(find.byType(HistorySheet))).pop();
    await tester.pumpAndSettle();
    pending.complete();
    await tester.pumpAndSettle();
    expect(copies, [_allHistory]);
    expect(find.text('Copied'), findsNothing);
    expect(state.current, '77');
    expect(tester.takeException(), isNull);
  });

  testWidgets('bulk controls remain reachable with large translated text', (
    tester,
  ) async {
    final copies = <String>[];
    mockClipboard(tester, (call) async {
      if (call.method == 'Clipboard.setData') {
        copies.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.binding.setSurfaceSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 3.2;
    await _open(tester, locale: const Locale('zh', 'HK'));
    await tester.ensureVisible(find.byKey(_bulkKey));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_bulkKey)).right, lessThanOrEqualTo(320));
    expect(
      tester.getSize(find.byKey(_bulkKey)).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(_bulkKey));
    await tester.pumpAndSettle();
    expect(copies, [_allHistory]);
    await tester.enterText(find.byKey(const ValueKey('history-search')), '4*5');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(_bulkKey));
    await tester.pumpAndSettle();
    expect(find.byTooltip(S.current.copyMatchingHistory), findsOneWidget);
    await tester.tap(find.byKey(_bulkKey));
    await tester.pumpAndSettle();
    expect(copies.last, '4 × 5 = 20');
    expect(tester.takeException(), isNull);
  });
}
