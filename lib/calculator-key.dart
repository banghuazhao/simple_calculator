import 'dart:math';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:simple_calculator/key-controller.dart' as keycontroller;
import 'package:simple_calculator/key-symbol.dart';
import 'package:simple_calculator/util/ThemeModel.dart';

abstract class Keys {
  static KeySymbol clear = const KeySymbol('C');
  static KeySymbol sign = const KeySymbol('±');
  static KeySymbol percent = const KeySymbol('%');
  static KeySymbol divide = const KeySymbol('÷');
  static KeySymbol multiply = const KeySymbol('x');
  static KeySymbol subtract = const KeySymbol('-');
  static KeySymbol add = const KeySymbol('+');
  static KeySymbol equals = const KeySymbol('=');
  static KeySymbol decimal = const KeySymbol('.');
  static KeySymbol back = const KeySymbol('←');

  static KeySymbol zero = const KeySymbol('0');
  static KeySymbol one = const KeySymbol('1');
  static KeySymbol two = const KeySymbol('2');
  static KeySymbol three = const KeySymbol('3');
  static KeySymbol four = const KeySymbol('4');
  static KeySymbol five = const KeySymbol('5');
  static KeySymbol six = const KeySymbol('6');
  static KeySymbol seven = const KeySymbol('7');
  static KeySymbol eight = const KeySymbol('8');
  static KeySymbol nine = const KeySymbol('9');
}

class CalculatorKey extends StatelessWidget {
  CalculatorKey({required this.symbol});

  final KeySymbol symbol;

  static dynamic _fire(CalculatorKey key) =>
      keycontroller.KeyController.fire(keycontroller.KeyEvent(key));

  @override
  Widget build(BuildContext context) {
    double size = (MediaQuery.of(context).size.width - 40) / 4;

    var model = Provider.of<ThemeModel>(context, listen: false);

    Color color;
    switch (symbol.type) {
      case KeyType.FUNCTION:
        color = model.buttonColor3;
        break;
      case KeyType.OPERATOR:
        color = model.buttonColor2;
        break;
      case KeyType.INTEGER:
      default:
        color = model.buttonColor1;
    }
    ;

    if (size > 150) {
      size = 150;
    }
    if (MediaQuery.of(context).size.height > 740) {
      double size2 = (MediaQuery
          .of(context)
          .size
          .height * 0.65 - 40) / 5;
      size = min(size, size2);
    }

    TextStyle style = Theme.of(context).textTheme.headlineSmall?.copyWith(color: model.textColor2) ?? TextStyle();

    return Container(
      padding: EdgeInsets.all(6),
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: () {
          _fire(this);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(12.0),
        ),
        child: Center(
          child: Text(symbol.value, style: style),
        ),
      ),
    );
    // InkWell(
    // onTap: () {
    //   HapticFeedback.lightImpact();
    //   _fire(this);
    // },
    // child: Container(
    //     width: size,
    //     height: size,
    //     child: Padding(
    //       padding: EdgeInsets.all(5),
    //
    //       child: Container(
    //           decoration: BoxDecoration(
    //               color: color, borderRadius: BorderRadius.all(Radius.circular(10))),
    //           child: Center(child: Text(symbol.value, style: style))),
    //
    //     )),
  }
}
