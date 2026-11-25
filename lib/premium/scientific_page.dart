import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/premium/expression_engine.dart';
import 'package:simple_calculator/premium/programmer_page.dart';
import 'package:simple_calculator/premium/scientific_graph_page.dart';
import 'package:simple_calculator/premium/scientific_history.dart';
import 'package:simple_calculator/premium/scientific_history_page.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/clipboard_helper.dart';
import 'package:simple_calculator/util/input_feedback.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';

class ScientificPage extends StatefulWidget {
  const ScientificPage({super.key, this.guard, this.canUse});

  static const anglePreferenceKey = 'scientific_angle_mode';

  final Widget Function(Widget)? guard;
  final bool Function()? canUse;

  @override
  State<ScientificPage> createState() => _ScientificPageState();
}

class _ScientificPageState extends State<ScientificPage> {
  static const _basicFunctions = [
    'sin',
    'cos',
    'tan',
    'asin',
    'acos',
    'atan',
    'sqrt',
    'log',
    'ln',
    'abs',
    'nCr',
    'nPr',
  ];
  static const _extraFunctions = [
    'sinh',
    'cosh',
    'tanh',
    'cbrt',
    'log2',
    'mod',
    'floor',
    'ceil',
    'round',
  ];
  static const _keys = [
    '(',
    ')',
    'Ans',
    'EXP',
    '⌫',
    '7',
    '8',
    '9',
    '÷',
    '^',
    '4',
    '5',
    '6',
    '×',
    '!',
    '1',
    '2',
    '3',
    '−',
    'π',
    '0',
    '.',
    ',',
    '+',
    '=',
  ];

  final _expression = TextEditingController();
  final _expressionFocus = FocusNode();
  final _editorAnchor = GlobalKey();
  final _resultAnchor = GlobalKey();
  final _history = ScientificHistory.instance;
  late bool _degrees;
  bool _engineering = false;
  bool _fraction = false;
  bool _secondFunctions = false;
  bool _showKeyboard = false;
  FormatException? _error;
  double? _result;
  double? _answer;
  ScientificHistoryEntry? _restoredEntry;

  double? get _inputAnswer =>
      _restoredEntry == null ? _answer : _restoredEntry!.answer;

  @override
  void initState() {
    super.initState();
    _degrees = _preferredDegrees();
    _answer = _history.entries.firstOrNull?.result;
  }

  bool _preferredDegrees() {
    try {
      return StorageManager.sharedPreferences?.get(
            ScientificPage.anglePreferenceKey,
          ) !=
          1;
    } catch (_) {
      return true;
    }
  }

  @override
  void dispose() {
    _expression.dispose();
    _expressionFocus.dispose();
    super.dispose();
  }

  double? _evaluatePreview() {
    final source = _expression.text.trim();
    if (source.isEmpty || _result != null) return null;
    final answer = _inputAnswer;
    try {
      final compiled = ExpressionEngine.compile(source);
      final value = compiled.evaluate(
        degrees: _degrees,
        variables: {
          if (answer != null)
            for (final name in compiled.variables)
              if (name.toLowerCase() == 'ans') name: answer,
        },
      );
      return value.isFinite ? value : null;
    } on FormatException {
      return null;
    }
  }

  void _calculate() {
    if (widget.canUse?.call() == false) return;
    final source = _expression.text;
    final answer = _inputAnswer;
    try {
      final compiled = ExpressionEngine.compile(source);
      final value = compiled.evaluate(
        degrees: _degrees,
        variables: {
          if (answer != null)
            for (final name in compiled.variables)
              if (name.toLowerCase() == 'ans') name: answer,
        },
      );
      unawaited(
        _history.add(
          ScientificHistoryEntry(
            expression: source,
            degrees: _degrees,
            answer: answer,
            result: value,
          ),
        ),
      );
      setState(() {
        _result = value;
        _answer = value;
        _error = null;
        _restoredEntry = null;
      });
      _reveal(_resultAnchor);
    } on FormatException catch (error) {
      setState(() {
        _result = null;
        _error = error;
      });
      if (error.offset case final offset?) {
        _expression.selection = TextSelection.collapsed(
          offset: offset.clamp(0, source.length),
        );
      }
      _reveal(_editorAnchor);
    }
  }

  void _reveal(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (key.currentContext case final target?) {
        unawaited(
          Scrollable.ensureVisible(
            target,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          ),
        );
      }
    });
  }

  void _clearResult() {
    setState(() {
      _result = null;
      _error = null;
    });
  }

  void _clear() {
    _expression.clear();
    _restoredEntry = null;
    _clearResult();
    _expressionFocus.requestFocus();
  }

  void _setDegrees(bool degrees) {
    if (_degrees == degrees && _preferredDegrees() == degrees) return;
    setState(() {
      _degrees = degrees;
      _result = null;
      _error = null;
    });
    unawaited(
      StorageManager.saveInt(
        ScientificPage.anglePreferenceKey,
        degrees ? 0 : 1,
      ),
    );
  }

  void _toggleKeyboard() {
    _expressionFocus.unfocus();
    setState(() => _showKeyboard = !_showKeyboard);
    if (_showKeyboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _expressionFocus.requestFocus();
      });
    }
  }

  void _insert(String token, {bool function = false, bool delete = false}) {
    final text = _expression.text;
    final selection = _expression.selection;
    final hasSelection = selection.isValid && selection.end <= text.length;
    var start = hasSelection ? selection.start : text.length;
    final end = hasSelection ? selection.end : text.length;
    if (delete && start == end && start > 0) {
      start -= text.substring(0, start).characters.last.length;
    }
    final selected = text.substring(start, end);
    final twoArguments = token == 'nCr' || token == 'nPr' || token == 'mod';
    final hasSelectedArgument = twoArguments && selected.isNotEmpty;
    final replacement = function
        ? '$token($selected${hasSelectedArgument ? ',' : ''})'
        : token;
    final updated = text.replaceRange(start, end, replacement);
    if (updated.length > ExpressionEngine.maxLength) return;
    final cursor = switch (function) {
      true when selected.isEmpty => start + token.length + 1,
      true when hasSelectedArgument => start + replacement.length - 1,
      _ => start + replacement.length,
    };
    _expression.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: cursor),
    );
    _clearResult();
    _expressionFocus.requestFocus();
  }

  void _pressKey(String key) {
    unawaited(InputFeedback.keyClick());
    switch (key) {
      case '=':
        _calculate();
      case '⌫':
        _insert('', delete: true);
      case 'EXP':
        _insert('E');
      default:
        _insert(key);
    }
  }

  Future<void> _openHistory() async {
    if (widget.canUse?.call() == false) return;
    final guard = widget.guard;
    final entry = await Navigator.of(context).push<ScientificHistoryEntry>(
      MaterialPageRoute(
        builder: (_) {
          const page = ScientificHistoryPage();
          return guard?.call(page) ?? page;
        },
      ),
    );
    if (!mounted || entry == null || widget.canUse?.call() == false) return;
    _expression.value = TextEditingValue(
      text: entry.expression,
      selection: TextSelection.collapsed(offset: entry.expression.length),
    );
    setState(() {
      _restoredEntry = entry;
      _degrees = entry.degrees;
      _result = null;
      _error = null;
    });
    _reveal(_editorAnchor);
  }

  void _openGraph() {
    if (widget.canUse?.call() == false) return;
    final page = ScientificGraphPage(
      initialExpression: _expression.text,
      degrees: _degrees,
      answer: _inputAnswer,
    );
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => widget.guard?.call(page) ?? page),
    );
  }

  void _openProgrammer() {
    if (widget.canUse?.call() == false) return;
    const page = ProgrammerPage();
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => widget.guard?.call(page) ?? page),
    );
  }

  void _useResult(double result) {
    if (widget.canUse?.call() == false) return;
    Processor.useResult(result);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _formatResult(double value) {
    if (_fraction) {
      final frac = ExpressionEngine.toFraction(value);
      if (frac != null) return frac;
    }
    if (!_engineering || value == 0) return Processor.formatResult(value);
    final parts = value.toStringAsExponential(14).split('e');
    final exponent = int.parse(parts[1]);
    final shift = exponent % 3;
    final engineeringExponent = exponent - shift;
    final mantissa = double.parse(parts[0]) * const [1, 10, 100][shift];
    final sign = engineeringExponent < 0 ? '' : '+';
    return '${Processor.formatResult(mantissa)}e$sign$engineeringExponent';
  }

  String? _errorText(S strings) {
    final error = _error;
    if (error == null) return null;
    if (error is! ExpressionException) {
      return strings.scientificInvalidExpression;
    }
    final message = switch (error.kind) {
      ExpressionError.syntax => strings.scientificSyntaxError,
      ExpressionError.missingClosingParenthesis =>
        strings.scientificMissingParen,
      ExpressionError.unknownFunction => strings.scientificUnknownFunction(
        error.identifier ?? '',
      ),
      ExpressionError.missingVariable
          when error.identifier?.toLowerCase() == 'ans' =>
        strings.scientificNoAnswer,
      ExpressionError.missingVariable => strings.scientificUnknownVariable(
        error.identifier ?? '',
      ),
      ExpressionError.divideByZero => strings.scientificDivideByZero,
      ExpressionError.domain => strings.scientificDomainError,
      ExpressionError.overflow => strings.scientificOverflow,
      ExpressionError.tooLong => strings.scientificTooLong,
      ExpressionError.tooDeep => strings.scientificTooDeep,
    };
    final offset = error.offset;
    return offset == null
        ? message
        : strings.scientificErrorPosition(message, offset + 1);
  }

  Widget _editor(S strings, ThemeModel model, bool useTouchKeyboard) {
    final ink = model.readableTextColor;
    final border = OutlineInputBorder(borderSide: BorderSide(color: ink));
    final error = _errorText(strings);
    final result = _result;
    final displayedResult = result == null ? null : _formatResult(result);
    final livePreview = result == null && error == null
        ? _evaluatePreview()
        : null;
    final textStyle = TextStyle(color: ink);

    ChoiceChip angleChip(String label, bool degrees) => ChoiceChip(
      label: Text(label),
      selected: _degrees == degrees,
      onSelected: (_) => _setDegrees(degrees),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: _editorAnchor,
          controller: _expression,
          focusNode: _expressionFocus,
          style: textStyle,
          keyboardType: useTouchKeyboard
              ? TextInputType.none
              : TextInputType.multiline,
          autocorrect: false,
          enableSuggestions: false,
          smartDashesType: SmartDashesType.disabled,
          minLines: 1,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            LengthLimitingTextInputFormatter(ExpressionEngine.maxLength),
          ],
          onChanged: (_) => _clearResult(),
          onSubmitted: (_) => _calculate(),
          decoration: InputDecoration(
            labelText: strings.scientificExpression,
            labelStyle: textStyle,
            errorText: error,
            errorStyle: textStyle,
            errorMaxLines: 4,
            border: border,
            enabledBorder: border,
            errorBorder: border,
            focusedErrorBorder: border,
            suffixIcon: IconButton(
              tooltip: strings.clearInput,
              color: ink,
              onPressed: _clear,
              icon: const Icon(Icons.clear),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          key: const ValueKey('scientific-live-preview-slot'),
          height: 24,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                livePreview != null
                    ? '= ${_formatResult(livePreview)}'
                    : strings.scientificExpressionHelp,
                key: livePreview != null
                    ? const ValueKey('scientific-live-preview')
                    : const ValueKey('scientific-expression-help'),
                maxLines: 1,
                softWrap: false,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: livePreview != null
                      ? ink
                      : (model.highContrastEnabled
                            ? ink
                            : ink.withValues(alpha: 0.7)),
                  fontWeight: livePreview != null ? FontWeight.w600 : null,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            angleChip(strings.scientificDegrees, true),
            angleChip(strings.scientificRadians, false),
            Tooltip(
              message: strings.scientificEngineeringNotation,
              child: FilterChip(
                label: const Text('ENG'),
                selected: _engineering,
                onSelected: (selected) => setState(() {
                  _engineering = selected;
                  if (selected) _fraction = false;
                }),
              ),
            ),
            Tooltip(
              message: strings.scientificFraction,
              child: FilterChip(
                key: const ValueKey('scientific-fraction-chip'),
                label: const Text('a/b'),
                selected: _fraction,
                onSelected: (selected) => setState(() {
                  _fraction = selected;
                  if (selected) _engineering = false;
                }),
              ),
            ),
          ],
        ),
        if (result != null && displayedResult != null) ...[
          const SizedBox(height: 8),
          DecoratedBox(
            key: _resultAnchor,
            decoration: BoxDecoration(
              color: model.panelColor,
              border: Border.all(color: model.panelBorderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.scientificResult,
                                style: TextStyle(color: model.panelTextColor),
                              ),
                              SelectableText(
                                displayedResult,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: model.panelTextColor,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: strings.copyResult,
                        icon: Icon(
                          Icons.copy_outlined,
                          color: model.panelTextColor,
                        ),
                        onPressed: () =>
                            ClipboardHelper.copy(context, displayedResult),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => _useResult(result),
                    icon: const Icon(Icons.calculate_outlined),
                    label: Text(strings.reuseResult),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String? _keyTooltip(String key, S strings) => switch (key) {
    '(' => strings.scientificOpenParenthesis,
    ')' => strings.scientificCloseParenthesis,
    'Ans' => strings.scientificPreviousAnswer,
    'EXP' => strings.scientificExponentEntry,
    '⌫' => strings.backspace,
    '^' => strings.scientificPower,
    '!' => strings.scientificFactorial,
    '÷' => strings.divide,
    '×' => strings.multiply,
    '−' => strings.subtract,
    '+' => strings.add,
    '.' => strings.decimalPoint,
    ',' => strings.scientificArgumentSeparator,
    '=' => strings.scientificEvaluate,
    _ => null,
  };

  Widget _key(String key, S strings, ThemeModel model) {
    final primary = key == '=';
    final digit = key.codeUnitAt(0) >= 48 && key.codeUnitAt(0) <= 57;
    final background = primary
        ? model.readableTextColor
        : digit || key == '.'
        ? model.buttonColor1
        : model.buttonColor2;
    final foreground = ThemeModel.readableOn(
      background,
      primary ? model.backgroundColor : model.textColor2,
    );
    final tooltip = _keyTooltip(key, strings);
    final button = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: background,
        padding: const EdgeInsets.all(4),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: model.highContrastEnabled ? BorderSide(color: foreground) : null,
      ),
      onPressed: () => _pressKey(key),
      child: key == '⌫'
          ? const Icon(Icons.backspace_outlined, size: 20)
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                key,
                style: TextStyle(
                  fontSize: key.length > 1 ? 14 : 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  Widget _keypad(S strings, ThemeModel model) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 272 ? 5 : 4;
        final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                for (final key in _keys)
                  SizedBox(width: width, child: _key(key, strings, model)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  key: const ValueKey('scientific-2nd-chip'),
                  label: const Text('2nd'),
                  selected: _secondFunctions,
                  onSelected: (selected) =>
                      setState(() => _secondFunctions = selected),
                ),
                for (final name in _secondFunctions
                    ? _extraFunctions
                    : _basicFunctions)
                  ActionChip(
                    label: Text(name),
                    onPressed: () {
                      unawaited(InputFeedback.keyClick());
                      _insert(name, function: true);
                    },
                  ),
                ActionChip(
                  label: const Text('e'),
                  onPressed: () {
                    unawaited(InputFeedback.keyClick());
                    _insert('e');
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final model = context.watch<ThemeModel>();
    final theme = Theme.of(context);
    final ink = model.readableTextColor;
    final mobile =
        theme.platform == TargetPlatform.android ||
        theme.platform == TargetPlatform.iOS;
    final editor = _editor(strings, model, mobile && !_showKeyboard);
    final keypad = _keypad(strings, model);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: ink,
          onPrimary: model.backgroundColor,
          secondaryContainer: ink,
          onSecondaryContainer: model.backgroundColor,
          surface: model.panelColor,
          onSurface: model.panelTextColor,
          onSurfaceVariant: model.panelTextColor,
          outline: ink,
        ),
      ),
      child: Scaffold(
        backgroundColor: model.backgroundColor,
        appBar: AppBar(
          backgroundColor: model.backgroundColor,
          foregroundColor: ink,
          title: Text(strings.scientificCalculator),
          actions: [
            if (mobile)
              IconButton(
                tooltip: _showKeyboard
                    ? strings.scientificHideKeyboard
                    : strings.scientificShowKeyboard,
                icon: Icon(
                  _showKeyboard ? Icons.keyboard_hide : Icons.keyboard_outlined,
                ),
                onPressed: _toggleKeyboard,
              ),
            IconButton(
              tooltip: strings.programmerMode,
              onPressed: _openProgrammer,
              icon: const Icon(Icons.memory),
            ),
            IconButton(
              tooltip: strings.scientificHistory,
              onPressed: _openHistory,
              icon: const Icon(Icons.history),
            ),
            IconButton(
              tooltip: strings.scientificGraph,
              onPressed: _openGraph,
              icon: const Icon(Icons.show_chart),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 780;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 1000 : 640),
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: editor),
                            const SizedBox(width: 24),
                            Expanded(child: keypad),
                          ],
                        )
                      else ...[
                        editor,
                        const SizedBox(height: 12),
                        keypad,
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
