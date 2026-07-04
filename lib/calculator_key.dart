import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/key_controller.dart' as keycontroller;
import 'package:simple_calculator/key_symbol.dart';
import 'package:simple_calculator/util/theme_model.dart';

abstract class Keys {
  static const KeySymbol clear = KeySymbol('C');
  static const KeySymbol sign = KeySymbol('±');
  static const KeySymbol percent = KeySymbol('%');
  static const KeySymbol divide = KeySymbol('÷');
  static const KeySymbol multiply = KeySymbol('×');
  static const KeySymbol subtract = KeySymbol('-');
  static const KeySymbol add = KeySymbol('+');
  static const KeySymbol equals = KeySymbol('=');
  static const KeySymbol decimal = KeySymbol('.');
  static const KeySymbol back = KeySymbol('⌫');

  static const KeySymbol zero = KeySymbol('0');
  static const KeySymbol one = KeySymbol('1');
  static const KeySymbol two = KeySymbol('2');
  static const KeySymbol three = KeySymbol('3');
  static const KeySymbol four = KeySymbol('4');
  static const KeySymbol five = KeySymbol('5');
  static const KeySymbol six = KeySymbol('6');
  static const KeySymbol seven = KeySymbol('7');
  static const KeySymbol eight = KeySymbol('8');
  static const KeySymbol nine = KeySymbol('9');
}

class CalculatorKey extends StatefulWidget {
  const CalculatorKey({Key? key, required this.symbol}) : super(key: key);
  final KeySymbol symbol;

  @override
  State<CalculatorKey> createState() => _CalculatorKeyState();
}

class _CalculatorKeyState extends State<CalculatorKey>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 70),
    reverseDuration: const Duration(milliseconds: 130),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.88)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    keycontroller.KeyController.fire(keycontroller.KeyEvent(widget));
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ThemeModel>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;

    double size = (screenSize.width - 40) / 4;
    if (size > 150) size = 150;
    if (screenSize.height > 740) {
      final heightBased = (screenSize.height * 0.60 - 40) / 5;
      size = min(size, heightBased);
    }

    final Color color;
    switch (widget.symbol.type) {
      case KeyType.function:
        color = model.buttonColor3;
        break;
      case KeyType.operator:
        color = model.buttonColor2;
        break;
      case KeyType.integer:
      default:
        color = model.buttonColor1;
    }

    final style = Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: model.textColor2,
              fontWeight: FontWeight.w500,
            ) ??
        const TextStyle();

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: SizedBox(
            width: size - 10,
            height: size - 10,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(widget.symbol.value, style: style),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
