import 'package:flutter/widgets.dart';
import 'package:simple_calculator/calculator-key.dart';

class KeyPad extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          CalculatorKey(symbol: Keys.clear),
          CalculatorKey(symbol: Keys.sign),
          CalculatorKey(symbol: Keys.percent),
          CalculatorKey(symbol: Keys.divide),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          CalculatorKey(symbol: Keys.seven),
          CalculatorKey(symbol: Keys.eight),
          CalculatorKey(symbol: Keys.nine),
          CalculatorKey(symbol: Keys.multiply),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          CalculatorKey(symbol: Keys.four),
          CalculatorKey(symbol: Keys.five),
          CalculatorKey(symbol: Keys.six),
          CalculatorKey(symbol: Keys.subtract),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          CalculatorKey(symbol: Keys.one),
          CalculatorKey(symbol: Keys.two),
          CalculatorKey(symbol: Keys.three),
          CalculatorKey(symbol: Keys.add),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          CalculatorKey(symbol: Keys.zero),
          CalculatorKey(symbol: Keys.decimal),
          CalculatorKey(symbol: Keys.back),
          CalculatorKey(symbol: Keys.equals),
        ])
      ]),
    );
  }
}
