import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/key_controller.dart';
import 'package:simple_calculator/key_symbol.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/history_storage.dart';
import 'package:simple_calculator/util/storage_manager.dart';

class _Preferences extends Fake implements SharedPreferences {
  final values = <String, Object>{};
  Future<bool> Function(String, String)? write;
  bool failRead = false;

  @override
  Object? get(String key) {
    if (failRead) throw PlatformException(code: 'read_failed');
    return values[key];
  }

  @override
  Future<bool> setString(String key, String value) {
    final writer = write;
    if (writer != null) return writer(key, value);
    values[key] = value;
    return Future<bool>.value(true);
  }
}

StoredCalculation _entry(int id, {String result = '3'}) =>
    StoredCalculation(id: id, equation: '1 + 2 =', result: result);

String _payload(List<Object?> entries, {Object version = 1}) =>
    jsonEncode({'version': version, 'entries': entries});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('history storage', () {
    late _Preferences preferences;
    late HistoryStorage storage;

    setUp(() {
      preferences = _Preferences();
      storage = HistoryStorage(
        preferences: () => preferences,
        writeTimeout: const Duration(milliseconds: 5),
      );
    });

    test(
      'roundtrips newest-first calculations without reformatting values',
      () async {
        await storage.save([
          const StoredCalculation(id: 2, equation: '9 ÷ 8 =', result: '1.125'),
          _entry(1, result: '3.0'),
        ]);

        final restored = storage.load();
        expect(restored.map((entry) => entry.id), [2, 1]);
        expect(restored.map((entry) => entry.equation), ['9 ÷ 8 =', '1 + 2 =']);
        expect(restored.map((entry) => entry.result), ['1.125', '3.0']);
      },
    );

    test(
      'missing, wrong-type, corrupt, or unknown-version history is ignored',
      () {
        for (final saved in <Object?>[
          null,
          true,
          12,
          'not json',
          '[]',
          '{}',
          _payload([_entry(1).toJson()], version: 2),
          jsonEncode({'version': 1, 'entries': 'wrong'}),
        ]) {
          if (saved == null) {
            preferences.values.clear();
          } else {
            preferences.values[HistoryStorage.preferencesKey] = saved;
          }
          expect(storage.load(), isEmpty, reason: '$saved');
        }
      },
    );

    test(
      'invalid records are skipped while valid finite values are retained',
      () {
        final invalid = <Object?>[
          null,
          'wrong',
          {'id': -1, 'equation': '1 + 2 =', 'result': '3'},
          {'id': 1.5, 'equation': '1 + 2 =', 'result': '3'},
          {
            'id': HistoryStorage.maxId + 1,
            'equation': '1 + 2 =',
            'result': '3',
          },
          {'id': 3, 'equation': 'untrusted text', 'result': '3'},
          {'id': 4, 'equation': 'NaN + 2 =', 'result': '3'},
          {'id': 5, 'equation': '1 + Infinity =', 'result': '3'},
          for (final result in ['-', '', 'Error', 'NaN', 'Infinity', '1e9999'])
            {'id': 6, 'equation': '1 + 2 =', 'result': result},
          {'id': 7, 'equation': '1 + 2 =', 'result': '1' * 65},
          _entry(8).toJson(),
          _entry(8, result: '4').toJson(),
          const StoredCalculation(
            id: 9,
            equation: '-1.25e-10 × 2 =',
            result: '-2.5e-10',
          ).toJson(),
        ];
        preferences.values[HistoryStorage.preferencesKey] = _payload(invalid);

        final restored = storage.load();
        expect(restored.map((entry) => entry.id), [8, 9]);
        expect(restored.last.result, '-2.5e-10');
      },
    );

    test('oversized JSON is ignored before parsing', () {
      preferences.values[HistoryStorage.preferencesKey] = ' ' * (64 * 1024 + 1);
      expect(storage.load(), isEmpty);
    });

    test(
      'load and save each retain at most 100 newest valid entries',
      () async {
        final entries = List.generate(110, (index) => _entry(110 - index));
        preferences.values[HistoryStorage.preferencesKey] = _payload(
          entries.map((entry) => entry.toJson()).toList(),
        );
        expect(storage.load(), hasLength(100));
        expect(storage.load().last.id, 11);

        await storage.save(entries);
        final saved =
            jsonDecode(
                  preferences.values[HistoryStorage.preferencesKey] as String,
                )
                as Map;
        expect(saved['entries'], hasLength(100));
        expect(storage.load().first.id, 110);
      },
    );

    test('unavailable or throwing preferences never prevent use', () async {
      final missing = HistoryStorage(preferences: () => null);
      expect(missing.load(), isEmpty);
      await missing.save([_entry(1)]);

      preferences.failRead = true;
      expect(storage.load(), isEmpty);
      final throwing = HistoryStorage(
        preferences: () {
          throw PlatformException(code: 'preferences_unavailable');
        },
      );
      expect(throwing.load(), isEmpty);
      await throwing.save([_entry(1)]);
    });

    test(
      'failed and declined writes do not escape or block a later save',
      () async {
        preferences.write = (_, _) async {
          throw PlatformException(code: 'write_failed');
        };
        await storage.save([_entry(1)]);
        preferences.write = (_, _) async => false;
        await storage.save([_entry(2)]);
        preferences.write = null;
        await storage.save([_entry(3)]);
        expect(storage.load().single.id, 3);
      },
    );

    test(
      'clear and delete cannot be overwritten by an older delayed write',
      () async {
        final first = Completer<bool>();
        final started = <String>[];
        preferences.write = (key, value) async {
          started.add(value);
          if (started.length == 1) await first.future;
          preferences.values[key] = value;
          return true;
        };

        final oldWrite = storage.save([_entry(1), _entry(2)]);
        final delete = storage.save([_entry(2)]);
        final clear = storage.save([]);
        // All callers have bounded waits, even if the native write stalls.
        await Future.wait([oldWrite, delete, clear, storage.flush()]);
        expect(started, hasLength(1));

        first.complete(true);
        await storage.flush();
        expect(started, hasLength(2));
        expect(storage.load(), isEmpty);
        expect((jsonDecode(started.last) as Map)['entries'], isEmpty);
      },
    );

    test(
      'deleting a record remains the latest snapshot after a late failure',
      () async {
        final first = Completer<bool>();
        var calls = 0;
        preferences.write = (key, value) async {
          calls++;
          if (calls == 1) await first.future;
          preferences.values[key] = value;
          return true;
        };
        final oldWrite = storage.save([_entry(1), _entry(2)]);
        final delete = storage.save([_entry(2)]);
        await Future.wait([oldWrite, delete]);
        expect(calls, 1);
        first.completeError(PlatformException(code: 'late_failure'));
        await storage.flush();
        expect(storage.load().single.id, 2);
      },
    );
  });

  group('processor persistence', () {
    late _Preferences preferences;
    late StreamSubscription<CalcState> subscription;
    late CalcState state;

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    Future<void> press(List<KeySymbol> symbols) async {
      for (final symbol in symbols) {
        Processor.process(KeyEvent(CalculatorKey(symbol: symbol)));
      }
      await settle();
    }

    setUp(() async {
      preferences = _Preferences();
      await StorageManager.init(loadPreferences: () async => preferences);
      Processor.restoreHistory();
      subscription = Processor.listen((value) => state = value);
      Processor.refresh();
      await settle();
      expect(state.current, '0');
      expect(Processor.canUndo, isFalse);
    });

    tearDown(() async {
      while (Processor.canUndo) {
        Processor.undo();
      }
      Processor.clearHistory();
      await HistoryStorage.instance.flush();
      await settle();
      await subscription.cancel();
    });

    test(
      'calculations survive restoring history and remain safe to recall',
      () async {
        await press([Keys.one, Keys.add, Keys.two, Keys.equals]);
        await HistoryStorage.instance.flush();
        final id = Processor.historyLog.single.id;

        Processor.restoreHistory();
        expect(Processor.historyLog.single.result, '3');
        expect(Processor.historyLog.single.id, id);
        Processor.setFromHistory(Processor.historyLog.single.result);
        await press([Keys.multiply, Keys.four, Keys.equals]);
        expect(state.current, '12');
        expect(Processor.historyLog.first.id, greaterThan(id));
      },
    );

    test(
      'history restoration leaves active input and undo untouched',
      () async {
        preferences.values[HistoryStorage.preferencesKey] = _payload([
          _entry(10).toJson(),
        ]);
        await press([Keys.eight, Keys.add, Keys.two]);
        Processor.restoreHistory();
        Processor.refresh();
        await settle();
        expect(state.current, '2');
        expect(state.history, '8 +');
        Processor.undo();
        await settle();
        expect(state.current, '8');
        expect(Processor.historyLog.single.id, 10);
      },
    );

    test(
      'deleted entries and cleared history stay absent after restoration',
      () async {
        await press([Keys.one, Keys.add, Keys.two, Keys.equals, Keys.clear]);
        await press([Keys.four, Keys.multiply, Keys.five, Keys.equals]);
        final deletedId = Processor.historyLog.first.id;
        Processor.removeHistoryEntry(deletedId);
        await HistoryStorage.instance.flush();
        Processor.restoreHistory();
        expect(Processor.historyLog.single.result, '3');

        Processor.clearHistory();
        await HistoryStorage.instance.flush();
        Processor.restoreHistory();
        expect(Processor.historyLog, isEmpty);
        expect(state.current, '20');
      },
    );

    test(
      'restored history is capped and new entries keep unique safe IDs',
      () async {
        preferences.values[HistoryStorage.preferencesKey] = _payload([
          _entry(HistoryStorage.maxId).toJson(),
          for (var index = 0; index < 109; index++) _entry(index).toJson(),
        ]);
        Processor.restoreHistory();
        expect(Processor.historyLog, hasLength(100));
        await press([Keys.one, Keys.add, Keys.two, Keys.equals]);
        expect(Processor.historyLog, hasLength(100));
        expect(
          Processor.historyLog.map((entry) => entry.id).toSet(),
          hasLength(100),
        );
        expect(Processor.historyLog.first.id, 99);
        await HistoryStorage.instance.flush();
        Processor.restoreHistory();
        expect(Processor.historyLog, hasLength(100));
      },
    );

    test(
      'invalid recalled numbers do not change input or create undo',
      () async {
        for (final invalid in ['', '-', 'NaN', 'Infinity', 'Error', '1e9999']) {
          Processor.setFromHistory(invalid);
        }
        await settle();
        expect(state.current, '0');
        expect(Processor.canUndo, isFalse);
        await press([Keys.two, Keys.add, Keys.three, Keys.equals]);
        expect(state.current, '5');
      },
    );

    test(
      'overflow from a recalled finite value shows error without saving it',
      () async {
        preferences.values[HistoryStorage.preferencesKey] = _payload([
          const StoredCalculation(
            id: 7,
            equation: '1e307 × 10 =',
            result: '1e308',
          ).toJson(),
        ]);
        Processor.restoreHistory();
        Processor.setFromHistory(Processor.historyLog.single.result);
        await press([Keys.multiply, Keys.nine, Keys.equals]);
        expect(state.current, 'Error');
        expect(Processor.historyLog, hasLength(1));
        expect(Processor.historyLog.single.result, '1e308');

        await press([Keys.two, Keys.add, Keys.three, Keys.equals]);
        expect(state.current, '5');
        await HistoryStorage.instance.flush();
        Processor.restoreHistory();
        expect(Processor.historyLog.map((entry) => entry.result), [
          '5',
          '1e308',
        ]);
      },
    );

    test(
      'percent handles an overflowing edited exponent and accepts fresh input',
      () async {
        Processor.setFromHistory('1e308');
        await press([Keys.nine, Keys.percent]);
        expect(state.current, 'Error');
        expect(Processor.historyLog, isEmpty);

        await press([Keys.one, Keys.add, Keys.two, Keys.equals]);
        expect(state.current, '3');
        await HistoryStorage.instance.flush();
        Processor.restoreHistory();
        expect(Processor.historyLog.single.result, '3');
      },
    );
  });
}
