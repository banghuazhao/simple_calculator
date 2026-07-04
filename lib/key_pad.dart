import 'package:flutter/widgets.dart';
import 'package:simple_calculator/calculator_key.dart';

class KeyPad extends StatelessWidget {
  const KeyPad({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
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
