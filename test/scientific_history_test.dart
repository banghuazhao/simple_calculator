import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/premium/scientific_history.dart';
import 'package:simple_calculator/premium/scientific_history_page.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';

class _Preferences extends Fake implements SharedPreferences {
  String? payload;
  Future<bool> Function(String)? write;

  @override
  Object? get(String key) => payload;

  @override
  Future<bool> setString(String key, String value) async {
    final saved = await (write?.call(value) ?? Future<bool>.value(true));
    if (saved) payload = value;
    return saved;
  }
}

const _entry = ScientificHistoryEntry(
  expression: 'sin(π / 2) + Ans',
  degrees: false,
  answer: 0.10000000000000002,
  result: 1.1,
);

ScientificHistoryEntry _number(int value) => ScientificHistoryEntry(
  expression: '$value',
  degrees: true,
  result: value.toDouble(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores expressions and full-precision evaluation context', () async {
    final preferences = _Preferences();
    final history = ScientificHistory(preferences: () => preferences);
    const precise = ScientificHistoryEntry(
      expression: 'Ans / 3',
      degrees: true,
      answer: 1,
      result: 0.3333333333333333,
    );
    await history.add(_entry);
    await history.add(precise);

    final restored = ScientificHistory(preferences: () => preferences).entries;
    expect(restored.map((entry) => entry.toJson()), [
      precise.toJson(),
      _entry.toJson(),
    ]);
  });

  test('skips malformed entries and keeps the newest records', () async {
    final preferences = _Preferences()
      ..payload = jsonEncode({
        'version': 1,
        'entries': [
          _entry.toJson(),
          {'expression': '', 'degrees': true, 'result': 2},
          {'expression': 'Ans', 'degrees': true, 'answer': '2', 'result': 2},
          ...List.generate(100, (index) => _number(index).toJson()),
        ],
      });
    final history = ScientificHistory(preferences: () => preferences);
    expect(history.entries, hasLength(ScientificHistory.maxEntries));
    expect(history.entries.first.toJson(), _entry.toJson());
    expect(history.entries.last.expression, '98');

    await history.add(
      const ScientificHistoryEntry(
        expression: '1 / 0',
        degrees: false,
        result: double.infinity,
      ),
    );
    expect(history.entries.first.toJson(), _entry.toJson());

    await history.add(_number(101));
    expect(history.entries, hasLength(ScientificHistory.maxEntries));
    expect(history.entries.first.expression, '101');
    expect(history.entries.last.expression, '97');
  });

  test(
    'coalesces parallel saves while preserving order after a failed write',
    () async {
      final firstWrite = Completer<bool>();
      var writes = 0;
      final preferences = _Preferences()
        ..write = (_) async {
          writes++;
          return writes == 1 ? firstWrite.future : true;
        };
      final history = ScientificHistory(preferences: () => preferences);

      final saves = [history.add(_number(1)), history.add(_number(2))];
      expect(writes, 1);
      saves.add(history.add(_number(3)));
      expect(history.entries.map((entry) => entry.expression), ['3', '2', '1']);
      firstWrite.complete(false);
      await Future.wait(saves);

      expect(writes, 2);
      final restored = ScientificHistory(
        preferences: () => preferences,
      ).entries;
      expect(restored.map((entry) => entry.expression), ['3', '2', '1']);
    },
  );

  testWidgets('selecting scientific history returns the record for editing', (
    tester,
  ) async {
    final preferences = _Preferences();
    await StorageManager.init(loadPreferences: () async => preferences);
    await ScientificHistory.instance.add(_entry);

    ScientificHistoryEntry? selected;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeModel(),
        child: MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selected = await Navigator.of(context)
                      .push<ScientificHistoryEntry>(
                        MaterialPageRoute(
                          builder: (_) => const ScientificHistoryPage(),
                        ),
                      );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Radians'), findsOneWidget);
    expect(find.text('= 1.1'), findsOneWidget);
    await tester.tap(find.text(_entry.expression));
    await tester.pumpAndSettle();

    expect(selected?.toJson(), _entry.toJson());
  });
}
