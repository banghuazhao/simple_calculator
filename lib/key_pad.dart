import 'package:flutter/widgets.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/processor.dart';

class KeyPad extends StatelessWidget {
  const KeyPad({
    super.key,
    this.activeOperator,
    this.clearShowsAllClear = false,
    this.canClearEntry = false,
  });

  final String? activeOperator;
  final bool clearShowsAllClear;
  final bool canClearEntry;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CalculatorKey(
                symbol: Keys.clear,
                labelOverride: clearShowsAllClear ? 'AC' : null,
                semanticsLabelOverride: clearShowsAllClear
                    ? strings.allClear
                    : canClearEntry
                    ? strings.clearEntry
                    : null,
                onTapOverride: canClearEntry ? Processor.clearEntry : null,
                onLongPress: Processor.clearAll,
              ),
              const CalculatorKey(symbol: Keys.sign),
              const CalculatorKey(symbol: Keys.percent),
              CalculatorKey(
                symbol: Keys.divide,
                isActive: activeOperator == Keys.divide.value,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const CalculatorKey(symbol: Keys.seven),
              const CalculatorKey(symbol: Keys.eight),
              const CalculatorKey(symbol: Keys.nine),
              CalculatorKey(
                symbol: Keys.multiply,
                isActive: activeOperator == Keys.multiply.value,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const CalculatorKey(symbol: Keys.four),
              const CalculatorKey(symbol: Keys.five),
              const CalculatorKey(symbol: Keys.six),
              CalculatorKey(
                symbol: Keys.subtract,
                isActive: activeOperator == Keys.subtract.value,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const CalculatorKey(symbol: Keys.one),
              const CalculatorKey(symbol: Keys.two),
              const CalculatorKey(symbol: Keys.three),
              CalculatorKey(
                symbol: Keys.add,
                isActive: activeOperator == Keys.add.value,
              ),
            ],
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CalculatorKey(symbol: Keys.zero),
              CalculatorKey(symbol: Keys.decimal),
              CalculatorKey(symbol: Keys.back),
              CalculatorKey(symbol: Keys.equals),
            ],
          ),
        ],
      ),
    );
  }
}
