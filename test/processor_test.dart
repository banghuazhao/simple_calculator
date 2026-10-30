import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/key_controller.dart';
import 'package:simple_calculator/key_symbol.dart';
import 'package:simple_calculator/processor.dart';

void main() {
  late CalcState state;
  late StreamSubscription<CalcState> subscription;

  Future<void> flushStates() => Future<void>.delayed(Duration.zero);

  Future<void> press(List<KeySymbol> symbols) async {
    for (final symbol in symbols) {
      Processor.process(KeyEvent(CalculatorKey(symbol: symbol)));
    }
    await flushStates();
  }

  Future<void> undo() async {
    Processor.undo();
    await flushStates();
  }

  setUp(() async {
    subscription = Processor.listen((value) => state = value);
    Processor.refresh();
    await flushStates();
    expect(state.current, '0');
    expect(Processor.canUndo, isFalse);
  });

  tearDown(() async {
    // Each case stays below the 30-entry undo limit, so draining the stack
    // restores the original zero without exposing a production reset API.
    while (Processor.canUndo) {
      Processor.undo();
    }
    Processor.clearHistory();
    await flushStates();
    await subscription.cancel();
  });

  test(
    'backspacing the last negative digit allows percent and further input',
    () async {
      await press([Keys.one, Keys.sign, Keys.back]);
      expect(state.current, '0');

      await press([Keys.percent, Keys.two, Keys.add, Keys.three, Keys.equals]);
      expect(state.current, '5');
      expect(state.isResult, isTrue);
    },
  );

  test(
    'backspacing a negative second operand permits replacement and percent',
    () async {
      await press([
        Keys.four,
        Keys.add,
        Keys.one,
        Keys.sign,
        Keys.back,
        Keys.percent,
      ]);
      // As with deleting a positive second operand, percent now applies to A.
      expect(state.current, '0.04');

      await press([Keys.two, Keys.equals]);
      expect(state.current, '2.04');
    },
  );

  for (final example in <(KeySymbol, String)>[
    (Keys.add, '11'),
    (Keys.subtract, '5'),
    (Keys.multiply, '24'),
    (Keys.divide, '2.6666666666666665'),
  ]) {
    test(
      'basic ${example.$1.value} arithmetic and history remain correct',
      () async {
        await press([Keys.eight, example.$1, Keys.three, Keys.equals]);

        expect(state.current, example.$2);
        expect(state.history, '8 ${example.$1.value} 3 =');
        expect(state.isResult, isTrue);
        expect(Processor.historyLog.single.result, example.$2);
      },
    );
  }

  test('decimal input ignores duplicate decimal points', () async {
    await press([
      Keys.one,
      Keys.decimal,
      Keys.decimal,
      Keys.five,
      Keys.add,
      Keys.two,
      Keys.decimal,
      Keys.two,
      Keys.five,
      Keys.equals,
    ]);
    expect(state.current, '3.75');
    expect(state.history, '1.5 + 2.25 =');
  });

  test(
    'division by zero shows an error and accepts a fresh calculation',
    () async {
      await press([Keys.one, Keys.divide, Keys.zero, Keys.equals]);
      expect(state.current, 'Error');
      expect(state.history, isEmpty);
      expect(Processor.historyLog, isEmpty);

      await press([Keys.two, Keys.add, Keys.three, Keys.equals]);
      expect(state.current, '5');
      expect(Processor.historyLog.single.result, '5');
    },
  );

  test(
    'undo is safe when empty and restores each input and result step',
    () async {
      await undo();
      expect(state.current, '0');
      expect(Processor.canUndo, isFalse);

      await press([Keys.one, Keys.two, Keys.add, Keys.three, Keys.equals]);
      expect(state.current, '15');
      expect(Processor.canUndo, isTrue);

      await undo();
      expect(state.current, '3');
      expect(state.history, '12 +');
      expect(state.isResult, isFalse);
      await undo();
      expect(state.current, '12');
      expect(state.history, '12 +');
      await undo();
      expect(state.current, '12');
      expect(state.history, isEmpty);
      await undo();
      expect(state.current, '1');
      await undo();
      expect(state.current, '0');
      expect(Processor.canUndo, isFalse);
      await undo();
      expect(state.current, '0');
      // Undo changes calculator input; completed history remains available.
      expect(Processor.historyLog.single.result, '15');
    },
  );

  test('undo after clear restores the complete result and equation', () async {
    await press([Keys.eight, Keys.add, Keys.two, Keys.equals, Keys.clear]);
    expect(state.current, '0');
    expect(state.history, isEmpty);

    await undo();
    expect(state.current, '10');
    expect(state.history, '8 + 2 =');
    expect(state.isResult, isTrue);
  });

  test(
    'history recall is undoable without adding another history entry',
    () async {
      await press([Keys.one, Keys.add, Keys.two, Keys.equals]);
      final entry = Processor.historyLog.single;
      await press([Keys.clear, Keys.seven]);

      Processor.setFromHistory(entry.result);
      await flushStates();
      expect(state.current, '3');
      expect(state.history, isEmpty);
      expect(state.isResult, isFalse);
      expect(Processor.historyLog, hasLength(1));

      await undo();
      expect(state.current, '7');
      expect(state.history, isEmpty);
    },
  );

  test(
    'deleting and clearing history preserves the displayed calculation',
    () async {
      await press([Keys.one, Keys.add, Keys.two, Keys.equals, Keys.clear]);
      await press([Keys.four, Keys.multiply, Keys.five, Keys.equals]);
      final entries = Processor.historyLog;
      expect(entries.map((entry) => entry.result), ['20', '3']);

      Processor.removeHistoryEntry(entries.first.id);
      expect(Processor.historyLog.single.result, '3');
      expect(state.current, '20');
      Processor.clearHistory();
      expect(Processor.historyLog, isEmpty);
      expect(state.current, '20');
    },
  );

  test('formatting preserves scientific notation exponent zeros', () async {
    await press([Keys.nine, Keys.divide, Keys.eight, Keys.equals]);
    await press(List.filled(5, Keys.percent));

    expect(double.parse(state.current), closeTo(1.125e-10, 1e-25));
    expect(state.current, endsWith('e-10'));
  });

  test(
    'backspacing scientific notation never leaves a partial exponent',
    () async {
      Processor.setFromHistory('1.125e-10');
      await flushStates();

      await press([Keys.back]);
      expect(state.current, '1.125e-1');
      await press([Keys.back]);
      expect(state.current, '1.125');
      await press([Keys.percent]);
      expect(state.current, '0.01125');
    },
  );
}
