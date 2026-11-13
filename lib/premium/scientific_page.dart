import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/premium/expression_engine.dart';
import 'package:simple_calculator/util/clipboard_helper.dart';
import 'package:simple_calculator/util/theme_model.dart';

class ScientificPage extends StatefulWidget {
  const ScientificPage({super.key});

  @override
  State<ScientificPage> createState() => _ScientificPageState();
}

class _ScientificPageState extends State<ScientificPage> {
  static const _functions = ['sqrt', 'log', 'ln', 'abs', 'sin', 'cos', 'tan'];
  static const _symbols = ['π', 'e', '+', '-', '*', '/', '^', '(', ')'];

  final _expression = TextEditingController();
  final _expressionFocus = FocusNode();
  bool _degrees = true;
  bool _hasError = false;
  String? _result;

  @override
  void dispose() {
    _expression.dispose();
    _expressionFocus.dispose();
    super.dispose();
  }

  void _calculate() {
    String? result;
    try {
      final value = ExpressionEngine.evaluate(
        _expression.text,
        degrees: _degrees,
      );
      result = _formatResult(value);
    } on FormatException {
      // The inline error stays visible until the next edit or calculation.
    }
    setState(() {
      _result = result;
      _hasError = result == null;
    });
  }

  String _formatResult(double value) {
    if (value == 0) return '0';
    final rounded = double.parse(value.toStringAsPrecision(15));
    final text = (rounded.isFinite ? rounded : value).toString();
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  void _clearResult() {
    if (_result == null && !_hasError) return;
    setState(() {
      _result = null;
      _hasError = false;
    });
  }

  void _setDegrees(bool degrees) {
    if (_degrees == degrees) return;
    setState(() {
      _degrees = degrees;
      _result = null;
      _hasError = false;
    });
  }

  void _insert(String token, {bool function = false}) {
    final text = _expression.text;
    final selection = _expression.selection;
    final hasSelection = selection.isValid && selection.end <= text.length;
    final start = hasSelection ? selection.start : text.length;
    final end = hasSelection ? selection.end : text.length;
    final selected = text.substring(start, end);
    final replacement = function ? '$token($selected)' : token;
    final updated = text.replaceRange(start, end, replacement);
    if (updated.length > ExpressionEngine.maxLength) return;
    final cursor = function && selected.isEmpty
        ? start + token.length + 1
        : start + replacement.length;
    _expression.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: cursor),
    );
    _clearResult();
    _expressionFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = context.watch<ThemeModel>();
    final textColor = theme.textColor1;
    final backgroundColor = theme.backgroundColor;
    final textStyle = TextStyle(color: textColor);
    final border = BorderSide(color: textColor);
    final result = _result;

    ChoiceChip angleChip(String label, bool degrees) {
      final selected = _degrees == degrees;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        labelStyle: TextStyle(color: selected ? backgroundColor : textColor),
        backgroundColor: backgroundColor,
        selectedColor: textColor,
        checkmarkColor: backgroundColor,
        side: border,
        onSelected: (_) => _setDegrees(degrees),
      );
    }

    ActionChip insertChip(String token, {bool function = false}) => ActionChip(
      label: Text(token),
      labelStyle: textStyle,
      backgroundColor: backgroundColor,
      side: border,
      onPressed: () => _insert(token, function: function),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        title: Text(strings.scientificCalculator),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                TextField(
                  controller: _expression,
                  focusNode: _expressionFocus,
                  style: textStyle,
                  autocorrect: false,
                  enableSuggestions: false,
                  smartDashesType: SmartDashesType.disabled,
                  minLines: 2,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      ExpressionEngine.maxLength,
                    ),
                  ],
                  onChanged: (_) => _clearResult(),
                  onSubmitted: (_) => _calculate(),
                  decoration: InputDecoration(
                    labelText: strings.scientificExpression,
                    labelStyle: textStyle,
                    helperText: strings.scientificExpressionHelp,
                    helperStyle: textStyle,
                    helperMaxLines: 4,
                    errorText: _hasError
                        ? strings.scientificInvalidExpression
                        : null,
                    errorStyle: textStyle,
                    errorMaxLines: 4,
                    border: OutlineInputBorder(borderSide: border),
                    enabledBorder: OutlineInputBorder(borderSide: border),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    angleChip(strings.scientificDegrees, true),
                    angleChip(strings.scientificRadians, false),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final function in _functions)
                      insertChip(function, function: true),
                    for (final symbol in _symbols) insertChip(symbol),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: textColor,
                    foregroundColor: backgroundColor,
                  ),
                  onPressed: _calculate,
                  child: Text(strings.scientificEvaluate),
                ),
                if (result != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            liveRegion: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.scientificResult,
                                  style: textStyle,
                                ),
                                SelectableText(
                                  result,
                                  style: textStyle.copyWith(fontSize: 28),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: strings.copyResult,
                          icon: Icon(Icons.copy_outlined, color: textColor),
                          onPressed: () =>
                              ClipboardHelper.copy(context, result),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
