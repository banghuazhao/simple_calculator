import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/key_controller.dart' as keycontroller;
import 'package:simple_calculator/key_symbol.dart';
import 'package:simple_calculator/util/input_feedback.dart';
import 'package:simple_calculator/util/input_settings.dart';
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
  const CalculatorKey({
    super.key,
    required this.symbol,
    this.isActive = false,
  });

  final KeySymbol symbol;
  final bool isActive;

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
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.96,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

  Timer? _holdDelay;
  Timer? _repeatTimer;
  bool _repeated = false;

  @override
  void dispose() {
    _cancelRepeat();
    _controller.dispose();
    super.dispose();
  }

  void _cancelRepeat() {
    _holdDelay?.cancel();
    _holdDelay = null;
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  void _onTapDown(TapDownDetails _) {
    _repeated = false;
    unawaited(InputFeedback.keyClick());
    if (!MediaQuery.disableAnimationsOf(context)) _controller.forward();
    if (widget.symbol == Keys.back) {
      _cancelRepeat();
      _holdDelay = Timer(const Duration(milliseconds: 380), () {
        if (!mounted) return;
        _repeated = true;
        _fireKey();
        _repeatTimer = Timer.periodic(const Duration(milliseconds: 75), (_) {
          if (!mounted) {
            _cancelRepeat();
            return;
          }
          unawaited(InputFeedback.lightImpact());
          _fireKey();
        });
      });
    }
  }

  void _onTapUp(TapUpDetails _) {
    _cancelRepeat();
    _controller.reverse();
    if (!_repeated) {
      _fireKey();
    }
    _repeated = false;
  }

  void _fireKey() {
    keycontroller.KeyController.fire(keycontroller.KeyEvent(widget));
  }

  void _onSemanticTap() {
    unawaited(InputFeedback.keyClick());
    _controller.reverse();
    _fireKey();
  }

  void _onTapCancel() {
    _cancelRepeat();
    _repeated = false;
    _controller.reverse();
  }

  String _accessibilityLabel(S strings) {
    switch (widget.symbol) {
      case Keys.clear:
        return strings.clearInput;
      case Keys.sign:
        return strings.changeSign;
      case Keys.percent:
        return strings.percent;
      case Keys.divide:
        return strings.divide;
      case Keys.multiply:
        return strings.multiply;
      case Keys.subtract:
        return strings.subtract;
      case Keys.add:
        return strings.add;
      case Keys.equals:
        return strings.equals;
      case Keys.decimal:
        return strings.decimalPoint;
      case Keys.back:
        return strings.backspace;
      default:
        return widget.symbol.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ThemeModel>(context);
    final screenSize = MediaQuery.of(context).size;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    double size = (screenSize.width - 40) / 4;
    if (size > 150) size = 150;
    // Landscape tablets and resizable windows can be wide but short. Android
    // 16 may ignore portrait locks, so height must cap the keypad at every size.
    final availableHeight =
        screenSize.height - MediaQuery.paddingOf(context).vertical;
    final heightBased = max(0.0, (availableHeight * 0.60 - 40) / 5);
    size = min(size, heightBased);

    final Color baseColor;
    switch (widget.symbol.type) {
      case KeyType.function:
        baseColor = model.buttonColor3;
        break;
      case KeyType.operator:
        baseColor = model.buttonColor2;
        break;
      case KeyType.integer:
        baseColor = model.buttonColor1;
    }

    final isActive = widget.isActive && widget.symbol.type == KeyType.operator;
    final baseForeground = ThemeModel.readableOn(baseColor, model.textColor2);
    final Color color = isActive ? baseForeground : baseColor;
    final Color foreground = isActive
        ? ThemeModel.readableOn(color, baseColor)
        : baseForeground;

    final isEquals = widget.symbol == Keys.equals;
    final style =
        Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: foreground,
          fontWeight: isEquals || isActive ? FontWeight.w700 : FontWeight.w500,
        ) ??
        const TextStyle();

    return ListenableBuilder(
      listenable: InputSettings.instance,
      builder: (context, _) {
        final displayLabel = widget.symbol == Keys.decimal
            ? InputSettings.instance.decimalSeparator
            : widget.symbol.value;
        final keyFace = Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: max(0.0, size - 8),
            height: max(0.0, size - 8),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                border: model.highContrastEnabled
                    ? Border.all(
                        color: isActive ? Colors.yellowAccent : Colors.white,
                        width: isActive ? 2.5 : 1.5,
                      )
                    : isActive
                    ? Border.all(color: baseColor, width: 2.5)
                    : isEquals
                    ? Border.all(
                        color: foreground.withValues(alpha: 0.5),
                        width: 2,
                      )
                    : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(displayLabel, style: style),
                ),
              ),
            ),
          ),
        );

        return Semantics(
          label: _accessibilityLabel(S.of(context)),
          button: true,
          selected: isActive ? true : null,
          onTap: _onSemanticTap,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: reduceMotion
                ? keyFace
                : ScaleTransition(scale: _scale, child: keyFace),
          ),
        );
      },
    );
  }
}
