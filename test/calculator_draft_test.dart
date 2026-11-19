import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/key_controller.dart';
import 'package:simple_calculator/key_symbol.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/calculator_draft_storage.dart';
import 'package:simple_calculator/util/history_storage.dart';
import 'package:simple_calculator/util/storage_manager.dart';

void _press(Iterable<KeySymbol> symbols) {
  for (final symbol in symbols) {
    Processor.process(KeyEvent(CalculatorKey(symbol: symbol)));
  }
}

Future<void> _restart() async {
  await CalculatorDraftStorage.instance.flush();
  await HistoryStorage.instance.flush();
  Processor.restoreHistory();
  Processor.restoreDraft();
}

class _DelayedPreferences extends Fake implements SharedPreferences {
  final firstWrite = Completer<bool>();
  final writes = <String>[];
  String? saved;

  @override
  Object? get(String key) => saved;

  @override
  Future<bool> setString(String key, String value) async {
    writes.add(value);
    if (writes.length == 1 && !await firstWrite.future) return false;
    saved = value;
    return true;
  }
}

CalculatorDraft _numberDraft(String text) => (
  valA: (text: text, preciseValue: null),
  valB: null,
  op: null,
  percentB: false,
  result: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await CalculatorDraftStorage.instance.flush();
    await HistoryStorage.instance.flush();
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
    Processor.restoreHistory();
    Processor.restoreDraft();
  });

  test(
    'restores a pending percentage and keeps completed history unique',
    () async {
      expect(Processor.paste('200'), isTrue);
      _press([Keys.add, Keys.one, Keys.zero, Keys.percent]);
      await _restart();

      var state = Processor.state;
      expect(state.leftOperand?.display, '200');
      expect(state.binaryOperator, '+');
      expect(state.rightOperand?.display, '10');
      expect(state.rightOperandIsPercent, isTrue);
      expect(state.isResult, isFalse);
      expect(state.canUndo, isFalse);
      expect(Processor.historyLog, isEmpty);

      _press([Keys.equals]);
      expect(Processor.state.current, '220');
      await _restart();
      state = Processor.state;
      expect(state.current, '220');
      expect(state.isResult, isTrue);
      _press([Keys.equals]);
      expect(Processor.historyLog.single.equation, '200 + 10% =');

      _press([Keys.clear]);
      await _restart();
      expect(Processor.state.current, '0');
      expect(Processor.state.history, isEmpty);
      expect(Processor.historyLog, hasLength(1));
    },
  );

  test('retains exact continuation values and the last undo action', () async {
    _press([Keys.one, Keys.divide, Keys.three, Keys.equals, Keys.multiply]);
    expect(Processor.paste('3'), isTrue);
    await _restart();
    expect(Processor.state.leftOperand?.input, (1 / 3).toString());
    _press([Keys.equals]);
    expect(Processor.state.current, '1');

    Processor.undo();
    await _restart();
    expect(Processor.state.isResult, isFalse);
    expect(Processor.state.binaryOperator, '×');
    expect(Processor.state.current, '3');
    expect(Processor.historyLog, hasLength(2));
  });

  test('retains an incomplete decimal exactly as entered', () async {
    _press([Keys.one, Keys.two, Keys.decimal]);
    await _restart();
    expect(Processor.state.current, '12.');
    _press([Keys.five]);
    expect(Processor.state.current, '12.5');
  });

  test(
    'corrects either operand of a result and preserves its original history',
    () async {
      Processor.paste('200');
      _press([Keys.add, Keys.one, Keys.zero, Keys.percent, Keys.equals]);
      final original = Processor.historyLog.single;
      final left = Processor.state.leftOperand!;
      expect(Processor.correctOperand(left, '100'), OperandCorrection.applied);
      expect(Processor.state.isResult, isFalse);
      expect(Processor.state.history, '100 + 10%');
      expect(Processor.historyLog.single, same(original));
      Processor.undo();
      expect(Processor.state.current, '220');

      final right = Processor.state.rightOperand!;
      expect(Processor.correctOperand(right, '5'), OperandCorrection.applied);
      await _restart();
      expect(Processor.state.history, '200 + 5%');
      _press([Keys.equals]);
      expect(Processor.state.current, '210');
      expect(Processor.historyLog.map((entry) => entry.equation), [
        '200 + 5% =',
        '200 + 10% =',
      ]);
    },
  );

  test(
    'rejects malformed text and stale edit dialogs without modifying input',
    () {
      final edit = Processor.state.leftOperand!;
      expect(
        Processor.correctOperand(edit, 'Infinity'),
        OperandCorrection.invalid,
      );
      expect(Processor.state.canUndo, isFalse);

      _press([Keys.one]);
      Processor.undo();
      expect(Processor.state.current, '0');
      expect(Processor.correctOperand(edit, '4'), OperandCorrection.stale);
      expect(Processor.state.current, '0');
      expect(Processor.state.canUndo, isFalse);
    },
  );

  test(
    'ignores invalid saved payloads without inventing a calculation',
    () async {
      final preferences = StorageManager.sharedPreferences!;
      final valid = {
        'version': 1,
        'left': {'text': '2'},
        'percent': false,
      };
      for (final invalid in [
        'not JSON',
        jsonEncode({...valid, 'version': 2}),
        jsonEncode({...valid, 'operator': '='}),
        jsonEncode({
          ...valid,
          'right': {'text': '3'},
        }),
        jsonEncode({...valid, 'percent': true}),
        jsonEncode({
          ...valid,
          'left': {'text': '1e999'},
        }),
      ]) {
        await preferences.setString(
          CalculatorDraftStorage.preferencesKey,
          invalid,
        );
        Processor.restoreDraft();
        expect(Processor.state.current, '0');
        expect(Processor.historyLog, isEmpty);
      }
    },
  );

  test('serializes writes and keeps only the latest pending draft', () async {
    final preferences = _DelayedPreferences();
    final storage = CalculatorDraftStorage(preferences: () => preferences);
    final first = storage.save(_numberDraft('1'));
    final second = storage.save(_numberDraft('2'));
    final third = storage.save(_numberDraft('3'));
    expect(preferences.writes, hasLength(1));
    preferences.firstWrite.complete(false);
    await Future.wait([first, second, third]);
    expect(preferences.writes, hasLength(2));
    expect(storage.load()?.valA.text, '3');
  });
}
