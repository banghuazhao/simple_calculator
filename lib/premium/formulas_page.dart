import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/premium/expression_engine.dart';
import 'package:simple_calculator/premium/formula_storage.dart';
import 'package:simple_calculator/util/clipboard_helper.dart';
import 'package:simple_calculator/util/theme_model.dart';

class FormulasPage extends StatefulWidget {
  const FormulasPage({super.key, this.guard, this.canEdit});

  final Widget Function(Widget)? guard;
  final bool Function()? canEdit;

  @override
  State<FormulasPage> createState() => _FormulasPageState();
}

class _FormulasPageState extends State<FormulasPage> {
  final _storage = FormulaStorage.instance;
  late List<SavedFormula> _formulas = _storage.load();
  bool _interactionPending = false;

  Future<bool> _persist(List<SavedFormula> formulas) async {
    if (!mounted || widget.canEdit?.call() == false) return false;
    final saved = await _storage.save(formulas);
    if (mounted && saved) setState(() => _formulas = formulas);
    return saved;
  }

  Future<void> _edit({int? index, SavedFormula? example}) async {
    if (_interactionPending || widget.canEdit?.call() == false) return;
    if (index == null && _formulas.length >= FormulaStorage.maxFormulas) {
      _showMessage(context, S.of(context).formulaLimitReached);
      return;
    }

    _interactionPending = true;
    final guard = widget.guard;
    final canEdit = widget.canEdit;
    final original = index == null ? example : _formulas[index];
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) {
            final editor = _FormulaEditor(
              formula: original,
              isNew: index == null,
              canEdit: canEdit,
              onSave: (formula) {
                if (!mounted) return Future.value(false);
                final updated = List<SavedFormula>.of(_formulas);
                if (index == null) {
                  updated.insert(0, formula);
                } else {
                  updated[index] = formula;
                }
                return _persist(updated);
              },
            );
            return guard?.call(editor) ?? editor;
          },
        ),
      );
    } finally {
      _interactionPending = false;
    }
  }

  Future<void> _delete(int index) async {
    if (_interactionPending || widget.canEdit?.call() == false) return;
    _interactionPending = true;
    try {
      final strings = S.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(strings.formulaDelete),
          content: Text(strings.formulaDeleteMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.formulaDelete),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true || widget.canEdit?.call() == false) {
        return;
      }

      final updated = List<SavedFormula>.of(_formulas)..removeAt(index);
      if (!await _persist(updated) && mounted) {
        _showMessage(context, strings.formulaSaveFailed);
      }
    } finally {
      _interactionPending = false;
    }
  }

  List<SavedFormula> _examples(S strings) => [
    SavedFormula(
      name: strings.formulaExampleOrderTotal,
      expression: 'quantity × unit_price',
      baseline: const {'quantity': 4, 'unit_price': 12.5},
      alternate: const {'quantity': 7, 'unit_price': 12.5},
    ),
    SavedFormula(
      name: strings.formulaExampleDiscount,
      expression: 'price × (1 - discount_percent / 100)',
      baseline: const {'price': 100, 'discount_percent': 10},
      alternate: const {'price': 100, 'discount_percent': 25},
    ),
    SavedFormula(
      name: strings.formulaExampleTax,
      expression: 'price × (1 + tax_percent / 100)',
      baseline: const {'price': 80, 'tax_percent': 8},
      alternate: const {'price': 80, 'tax_percent': 12},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ThemeModel>();
    final strings = S.of(context);
    return _FormulaScaffold(
      title: strings.reusableFormulas,
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _formulas.isEmpty ? 2 : _formulas.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  onPressed: _edit,
                  icon: const Icon(Icons.add),
                  label: Text(strings.formulaNew),
                ),
                ExpansionTile(
                  key: PageStorageKey(
                    _formulas.isEmpty
                        ? 'formula-examples-empty'
                        : 'formula-examples',
                  ),
                  initiallyExpanded: _formulas.isEmpty,
                  tilePadding: EdgeInsets.zero,
                  leading: const Icon(Icons.auto_stories_outlined),
                  title: Text(strings.formulaExamples),
                  children: [
                    for (final example in _examples(strings))
                      ListTile(
                        title: Text(example.name),
                        subtitle: Text(example.expression),
                        onTap: () => _edit(example: example),
                      ),
                  ],
                ),
              ],
            );
          }
          if (_formulas.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(strings.formulaEmpty),
            );
          }
          final formula = _formulas[index - 1];
          return Card(
            margin: const EdgeInsets.only(top: 10),
            elevation: 0,
            color: model.textColor1.withValues(alpha: 0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: model.dividerColor),
            ),
            child: ListTile(
              title: Text(
                formula.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                formula.expression,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _edit(index: index - 1),
              trailing: IconButton(
                tooltip: strings.formulaDelete,
                onPressed: () => _delete(index - 1),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FormulaEditor extends StatefulWidget {
  const _FormulaEditor({
    required this.formula,
    required this.isNew,
    required this.onSave,
    this.canEdit,
  });

  final SavedFormula? formula;
  final bool isNew;
  final Future<bool> Function(SavedFormula) onSave;
  final bool Function()? canEdit;

  @override
  State<_FormulaEditor> createState() => _FormulaEditorState();
}

class _FormulaEditorState extends State<_FormulaEditor> {
  late String _name = widget.formula?.name ?? '';
  late String _expression = widget.formula?.expression ?? '';
  late final _baseline = _editableValues(widget.formula?.baseline);
  late final _alternate = _editableValues(widget.formula?.alternate);
  Set<String>? _variables;
  bool _submitted = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _parseExpression();
  }

  Map<String, String> _editableValues(Map<String, double>? values) =>
      values?.map((name, value) => MapEntry(name, _numberText(value))) ?? {};

  void _parseExpression() {
    try {
      final variables = ExpressionEngine.variablesIn(_expression.trim());
      _variables = variables;
      if (variables.length > FormulaStorage.maxInputs) return;
      _baseline.removeWhere((name, _) => !variables.contains(name));
      _alternate.removeWhere((name, _) => !variables.contains(name));
    } on FormatException {
      _variables = null;
    }
  }

  bool get _nameValid =>
      _name.trim().isNotEmpty &&
      _name.trim().length <= FormulaStorage.maxNameLength;

  Map<String, double>? _parsedInputs(Map<String, String> input) {
    final parsed = <String, double>{};
    for (final name in _variables ?? const <String>{}) {
      final text = input[name] ?? '';
      if (text.trim().isEmpty) continue;
      final value = FormulaStorage.parseValue(text);
      if (value == null) return null;
      parsed[name] = value;
    }
    return parsed;
  }

  ({double? value, bool error}) _calculate(Map<String, String> input) {
    final variables = _variables;
    final values = _parsedInputs(input);
    if (variables == null ||
        values == null ||
        values.length != variables.length) {
      return (value: null, error: false);
    }
    try {
      final value = ExpressionEngine.evaluate(
        _expression.trim(),
        variables: values,
      );
      return (value: value.isFinite ? value : null, error: !value.isFinite);
    } on FormatException {
      return (value: null, error: true);
    }
  }

  Future<void> _save() async {
    if (_saving || widget.canEdit?.call() == false) return;
    setState(() => _submitted = true);
    final variables = _variables;
    final baseline = _parsedInputs(_baseline);
    final alternate = _parsedInputs(_alternate);
    if (!_nameValid ||
        variables == null ||
        variables.length > FormulaStorage.maxInputs ||
        baseline == null ||
        alternate == null) {
      return;
    }

    setState(() => _saving = true);
    final saved = await widget.onSave(
      SavedFormula(
        name: _name.trim(),
        expression: _expression.trim(),
        baseline: baseline,
        alternate: alternate,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      Navigator.pop(context);
    } else {
      _showMessage(context, S.of(context).formulaSaveFailed);
    }
  }

  Widget _scenario({
    required String title,
    required String keyPrefix,
    required Map<String, String> input,
    required ({double? value, bool error}) result,
  }) {
    final strings = S.of(context);
    final model = context.watch<ThemeModel>();
    final value = result.value;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: model.textColor1.withValues(alpha: 0.06),
        border: Border.all(color: model.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: model.textColor1),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value != null
                  ? _resultText(value)
                  : result.error
                  ? strings.error
                  : strings.formulaNoResult,
              key: ValueKey('formula-$keyPrefix-result'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: model.textColor1),
            ),
            for (final variable in _variables!)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  hint: title,
                  child: TextFormField(
                    key: ValueKey('formula-$keyPrefix-$variable'),
                    initialValue: input[variable],
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    maxLength: FormulaStorage.maxValueLength,
                    decoration: InputDecoration(
                      labelText: variable,
                      counterText: '',
                      errorText:
                          _submitted &&
                              (input[variable]?.trim().isNotEmpty ?? false) &&
                              FormulaStorage.parseValue(input[variable]!) ==
                                  null
                          ? strings.formulaInvalidInput
                          : null,
                    ),
                    onChanged: (value) =>
                        setState(() => input[variable] = value),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _comparison(S strings) {
    final model = context.watch<ThemeModel>();
    final baseline = _calculate(_baseline);
    final alternate = _calculate(_alternate);
    final baselineValue = baseline.value;
    final alternateValue = alternate.value;
    final difference = baselineValue != null && alternateValue != null
        ? alternateValue - baselineValue
        : null;
    final differenceText = difference != null && difference.isFinite
        ? _resultText(difference)
        : null;
    final baselineCard = _scenario(
      title: strings.formulaBaseline,
      keyPrefix: 'baseline',
      input: _baseline,
      result: baseline,
    );
    final alternateCard = _scenario(
      title: strings.formulaAlternate,
      keyPrefix: 'alternate',
      input: _alternate,
      result: alternate,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 600 &&
                MediaQuery.textScalerOf(context).scale(16) <= 24) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: baselineCard),
                  const SizedBox(width: 12),
                  Expanded(child: alternateCard),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                baselineCard,
                const SizedBox(height: 12),
                alternateCard,
              ],
            );
          },
        ),
        if (difference != null) ...[
          const SizedBox(height: 16),
          Text(strings.formulaDifference),
          Text(
            differenceText ?? strings.error,
            key: const ValueKey('formula-difference-result'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: model.textColor1),
          ),
        ],
        if (baselineValue != null &&
            alternateValue != null &&
            differenceText != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () {
                final name = _name.trim();
                final comparison = [
                  if (name.isNotEmpty) name,
                  _expression.trim(),
                  '${strings.formulaBaseline}: ${_resultText(baselineValue)}',
                  '${strings.formulaAlternate}: ${_resultText(alternateValue)}',
                  '${strings.formulaDifference}: $differenceText',
                ].join('\n');
                ClipboardHelper.copy(context, comparison);
              },
              icon: const Icon(Icons.copy_outlined),
              label: Text(strings.formulaCopyComparison),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final variables = _variables;
    final tooManyInputs = (variables?.length ?? 0) > FormulaStorage.maxInputs;
    return PopScope(
      canPop: !_saving,
      child: _FormulaScaffold(
        title: widget.isNew ? strings.formulaNew : strings.formulaEdit,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(strings.formulaSave),
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            TextFormField(
              key: const ValueKey('formula-name'),
              initialValue: _name,
              enabled: !_saving,
              maxLength: FormulaStorage.maxNameLength,
              decoration: InputDecoration(
                labelText: strings.formulaName,
                counterText: '',
                errorText: _submitted && !_nameValid
                    ? strings.formulaInvalidName
                    : null,
              ),
              onChanged: (value) => setState(() => _name = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('formula-expression'),
              initialValue: _expression,
              enabled: !_saving,
              maxLength: ExpressionEngine.maxLength,
              maxLines: 3,
              minLines: 1,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: strings.formulaExpression,
                helperText: strings.formulaExpressionHint,
                helperMaxLines: 2,
                counterText: '',
                errorText: tooManyInputs
                    ? strings.formulaTooManyInputs
                    : _submitted && variables == null
                    ? strings.formulaInvalidExpression
                    : null,
              ),
              onChanged: (value) => setState(() {
                _expression = value;
                _parseExpression();
              }),
            ),
            if (variables != null && !tooManyInputs) ...[
              const SizedBox(height: 20),
              _comparison(strings),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormulaScaffold extends StatelessWidget {
  const _FormulaScaffold({
    required this.title,
    required this.body,
    this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ThemeModel>();
    final theme = Theme.of(context);
    final brightness = ThemeData.estimateBrightnessForColor(
      model.backgroundColor,
    );
    final baseScheme = theme.brightness == brightness
        ? theme.colorScheme
        : brightness == Brightness.dark
        ? const ColorScheme.dark()
        : const ColorScheme.light();
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(
          bodyColor: model.textColor1,
          displayColor: model.textColor1,
        ),
        colorScheme: baseScheme.copyWith(
          primary: model.textColor1,
          onPrimary: model.backgroundColor,
          surface: model.backgroundColor,
          onSurface: model.textColor1,
          onSurfaceVariant: model.textColor1,
          outline: model.mutedTextColor,
        ),
        inputDecorationTheme: const InputDecorationThemeData(
          border: OutlineInputBorder(),
          errorMaxLines: 3,
        ),
      ),
      child: Scaffold(
        backgroundColor: model.backgroundColor,
        appBar: AppBar(
          backgroundColor: model.backgroundColor,
          foregroundColor: model.textColor1,
          surfaceTintColor: Colors.transparent,
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: actions,
        ),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

String _numberText(double value) =>
    value == 0 ? '0' : value.toString().replaceFirst(RegExp(r'\.0(?=e|$)'), '');

String _resultText(double value) {
  final rounded = double.parse(value.toStringAsPrecision(12));
  return _numberText(rounded.isFinite ? rounded : value);
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
