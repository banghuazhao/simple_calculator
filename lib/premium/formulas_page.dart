import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/premium/expression_engine.dart';
import 'package:simple_calculator/premium/formula_storage.dart';
import 'package:simple_calculator/processor.dart';
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
  final _search = TextEditingController();
  late List<SavedFormula> _formulas = _storage.load();
  String _query = '';
  bool _interactionPending = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<bool> _persist(List<SavedFormula> formulas) async {
    if (!mounted || widget.canEdit?.call() == false) return false;
    final saved = await _storage.save(formulas);
    if (mounted && saved) setState(() => _formulas = formulas);
    return saved;
  }

  Future<void> _openFormula({
    int? index,
    SavedFormula? example,
    bool runFirst = false,
  }) async {
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
            final workspace = _FormulaWorkspace(
              formula: original,
              isNew: index == null,
              runFirst: runFirst,
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
            return guard?.call(workspace) ?? workspace;
          },
        ),
      );
    } finally {
      _interactionPending = false;
    }
  }

  Future<void> _duplicate(int index) async {
    if (_interactionPending || widget.canEdit?.call() == false) return;
    if (_formulas.length >= FormulaStorage.maxFormulas) {
      _showMessage(context, S.of(context).formulaLimitReached);
      return;
    }
    _interactionPending = true;
    try {
      final original = _formulas[index];
      final suffix = ' (copy)';
      final maxBase = FormulaStorage.maxNameLength - suffix.length;
      final baseName = original.name.length > maxBase
          ? original.name.substring(0, maxBase)
          : original.name;
      final copy = SavedFormula(
        name: '$baseName$suffix',
        expression: original.expression,
        baseline: Map<String, double>.of(original.baseline),
        alternate: Map<String, double>.of(original.alternate),
        inputMetadata: Map<String, FormulaInputMetadata>.of(
          original.inputMetadata,
        ),
        baselineName: original.baselineName,
        alternateName: original.alternateName,
      );
      final updated = List<SavedFormula>.of(_formulas)..insert(index + 1, copy);
      if (!await _persist(updated) && mounted) {
        _showMessage(context, S.of(context).formulaSaveFailed);
      }
    } finally {
      _interactionPending = false;
    }
  }

  Future<void> _move(int index, int delta) async {
    final target = index + delta;
    if (target < 0 ||
        target >= _formulas.length ||
        _interactionPending ||
        widget.canEdit?.call() == false) {
      return;
    }
    _interactionPending = true;
    try {
      final updated = List<SavedFormula>.of(_formulas);
      final item = updated.removeAt(index);
      updated.insert(target, item);
      await _persist(updated);
    } finally {
      _interactionPending = false;
    }
  }

  Future<void> _delete(int index) async {
    if (_interactionPending || widget.canEdit?.call() == false) return;
    _interactionPending = true;
    try {
      final strings = S.of(context);
      final model = context.read<ThemeModel>();
      final ink = model.readableTextColor;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          backgroundColor: model.backgroundColor,
          title: Text(strings.formulaDelete, style: TextStyle(color: ink)),
          content: Text(
            strings.formulaDeleteMessage,
            style: TextStyle(color: ink),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.cancel, style: TextStyle(color: ink)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.formulaDelete, style: TextStyle(color: ink)),
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
    SavedFormula(
      name: strings.formulaExampleLoan,
      expression:
          'principal * (rate / 1200) / (1 - (1 + rate / 1200)^(-months))',
      baseline: const {'principal': 250000, 'rate': 6.0, 'months': 360},
      alternate: const {'principal': 250000, 'rate': 5.5, 'months': 360},
    ),
    SavedFormula(
      name: strings.formulaExampleCompound,
      expression: 'principal * (1 + rate / 100)^years',
      baseline: const {'principal': 10000, 'rate': 5, 'years': 10},
      alternate: const {'principal': 10000, 'rate': 7, 'years': 10},
    ),
    SavedFormula(
      name: strings.formulaExampleMargin,
      expression: '(price - cost) / price * 100',
      baseline: const {'price': 100, 'cost': 65},
      alternate: const {'price': 110, 'cost': 65},
    ),
    SavedFormula(
      name: strings.formulaExampleBmi,
      expression: 'weight_kg / (height_m ^ 2)',
      baseline: const {'weight_kg': 70, 'height_m': 1.75},
      alternate: const {'weight_kg': 65, 'height_m': 1.75},
    ),
    SavedFormula(
      name: strings.formulaExampleFuel,
      expression: 'distance_km / 100 * liters_per_100km * price_per_liter',
      baseline: const {
        'distance_km': 300,
        'liters_per_100km': 8,
        'price_per_liter': 2.5,
      },
      alternate: const {
        'distance_km': 300,
        'liters_per_100km': 6,
        'price_per_liter': 2.5,
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ThemeModel>();
    final strings = S.of(context);
    final q = _query.trim().toLowerCase();
    final visibleIndices = <int>[
      for (var i = 0; i < _formulas.length; i++)
        if (q.isEmpty ||
            _formulas[i].name.toLowerCase().contains(q) ||
            _formulas[i].expression.toLowerCase().contains(q))
          i,
    ];

    return _FormulaScaffold(
      title: strings.reusableFormulas,
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _formulas.isEmpty ? 2 : visibleIndices.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  onPressed: _openFormula,
                  icon: const Icon(Icons.add),
                  label: Text(strings.formulaNew),
                ),
                if (_formulas.length >= 3) ...[
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('formula-search'),
                    controller: _search,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      labelText: strings.formulaSearch,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: strings.clearSearch,
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                ],
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
                        onTap: () => _openFormula(example: example),
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
          final realIndex = visibleIndices[index - 1];
          final formula = _formulas[realIndex];
          return Card(
            margin: const EdgeInsets.only(top: 10),
            elevation: 0,
            color: model.panelColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: model.panelBorderColor),
            ),
            child: ListTile(
              title: Text(
                formula.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: model.panelTextColor),
              ),
              subtitle: Text(
                formula.expression,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: model.panelTextColor),
              ),
              onTap: () => _openFormula(index: realIndex, runFirst: true),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (q.isEmpty && _formulas.length > 1) ...[
                    if (realIndex > 0)
                      IconButton(
                        tooltip: strings.formulaMoveUp,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _move(realIndex, -1),
                        icon: const Icon(Icons.arrow_upward, size: 18),
                      ),
                    if (realIndex < _formulas.length - 1)
                      IconButton(
                        tooltip: strings.formulaMoveDown,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _move(realIndex, 1),
                        icon: const Icon(Icons.arrow_downward, size: 18),
                      ),
                  ],
                  IconButton(
                    tooltip: strings.formulaDuplicate,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _duplicate(realIndex),
                    icon: const Icon(Icons.copy_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: strings.formulaDelete,
                    onPressed: () => _delete(realIndex),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FormulaWorkspace extends StatefulWidget {
  const _FormulaWorkspace({
    required this.formula,
    required this.isNew,
    required this.runFirst,
    required this.onSave,
    this.canEdit,
  });

  final SavedFormula? formula;
  final bool isNew;
  final bool runFirst;
  final Future<bool> Function(SavedFormula) onSave;
  final bool Function()? canEdit;

  @override
  State<_FormulaWorkspace> createState() => _FormulaWorkspaceState();
}

class _FormulaWorkspaceState extends State<_FormulaWorkspace> {
  late bool _editing = !widget.runFirst;
  late String _name = widget.formula?.name ?? '';
  late String _expression = widget.formula?.expression ?? '';
  late String _baselineName = widget.formula?.baselineName ?? '';
  late String _alternateName = widget.formula?.alternateName ?? '';
  late final _baseline = _editableValues(widget.formula?.baseline);
  late final _alternate = _editableValues(widget.formula?.alternate);
  late final _labels =
      widget.formula?.inputMetadata.map(
        (name, metadata) => MapEntry(name, metadata.label),
      ) ??
      <String, String>{};
  late final _units =
      widget.formula?.inputMetadata.map(
        (name, metadata) => MapEntry(name, metadata.unit),
      ) ??
      <String, String>{};
  String? _compiledSource;
  CompiledExpression? _compiled;
  bool _submitted = false;
  bool _saving = false;

  Set<String>? get _variables => _compiled?.variables;

  @override
  void initState() {
    super.initState();
    _parseExpression();
  }

  Map<String, String> _editableValues(Map<String, double>? values) =>
      values?.map((name, value) => MapEntry(name, _numberText(value))) ?? {};

  void _parseExpression() {
    final source = _expression.trim();
    if (_compiledSource == source) return;
    _compiledSource = source;
    try {
      final compiled = ExpressionEngine.compile(source);
      _compiled = compiled;
      final variables = compiled.variables;
      if (variables.length > FormulaStorage.maxInputs) return;
      _baseline.removeWhere((name, _) => !variables.contains(name));
      _alternate.removeWhere((name, _) => !variables.contains(name));
      _labels.removeWhere((name, _) => !variables.contains(name));
      _units.removeWhere((name, _) => !variables.contains(name));
    } on FormatException {
      _compiled = null;
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
    final compiled = _compiled;
    if (compiled == null) return (value: null, error: false);
    final values = _parsedInputs(input);
    if (values == null || values.length != compiled.variables.length) {
      return (value: null, error: false);
    }
    try {
      final value = compiled.evaluate(variables: values);
      return (value: value.isFinite ? value : null, error: !value.isFinite);
    } on FormatException {
      return (value: null, error: true);
    }
  }

  void _useInCalculator(double value) {
    Processor.useResult(value);
    Navigator.of(context).popUntil((route) => route.isFirst);
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
    final inputMetadata = <String, FormulaInputMetadata>{};
    for (final variable in variables) {
      final label = _labels[variable]?.trim() ?? '';
      final unit = _units[variable]?.trim() ?? '';
      if (label.isNotEmpty || unit.isNotEmpty) {
        inputMetadata[variable] = FormulaInputMetadata(
          label: label,
          unit: unit,
        );
      }
    }
    final saved = await widget.onSave(
      SavedFormula(
        name: _name.trim(),
        expression: _expression.trim(),
        baseline: baseline,
        alternate: alternate,
        inputMetadata: inputMetadata,
        baselineName: _baselineName.trim(),
        alternateName: _alternateName.trim(),
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

  String _inputLabel(String variable) {
    final customLabel = _labels[variable]?.trim() ?? '';
    final label = customLabel.isEmpty ? variable : customLabel;
    final unit = _units[variable]?.trim() ?? '';
    return unit.isEmpty ? label : '$label ($unit)';
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
        color: model.panelColor,
        border: Border.all(color: model.panelBorderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: model.panelTextColor,
                      ),
                    ),
                  ),
                ),
                if (value != null)
                  IconButton(
                    tooltip: strings.reuseResult,
                    visualDensity: VisualDensity.compact,
                    color: model.panelTextColor,
                    icon: const Icon(Icons.calculate_outlined, size: 20),
                    onPressed: () => _useInCalculator(value),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value != null
                  ? _resultText(value)
                  : result.error
                  ? strings.error
                  : strings.formulaNoResult,
              key: ValueKey('formula-$keyPrefix-result'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: model.panelTextColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
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
                      labelText: _inputLabel(variable),
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
    final percentChange =
        difference != null &&
            difference.isFinite &&
            baselineValue != null &&
            baselineValue != 0
        ? (difference / baselineValue.abs()) * 100
        : null;
    final percentText = percentChange != null && percentChange.isFinite
        ? '${percentChange >= 0 ? '+' : ''}${_resultText(percentChange)}%'
        : null;
    final baselineName = _baselineName.trim();
    final alternateName = _alternateName.trim();
    final baselineTitle = baselineName.isEmpty
        ? strings.formulaBaseline
        : baselineName;
    final alternateTitle = alternateName.isEmpty
        ? strings.formulaAlternate
        : alternateName;
    final differenceTitle = baselineName.isEmpty && alternateName.isEmpty
        ? strings.formulaDifference
        : strings.formulaNamedDifference(alternateTitle, baselineTitle);
    final baselineCard = _scenario(
      title: baselineTitle,
      keyPrefix: 'baseline',
      input: _baseline,
      result: baseline,
    );
    final alternateCard = _scenario(
      title: alternateTitle,
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
          Text(differenceTitle),
          Row(
            children: [
              Text(
                differenceText ?? strings.error,
                key: const ValueKey('formula-difference-result'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: model.textColor1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (percentText != null) ...[
                const SizedBox(width: 10),
                Text(
                  '($percentText)',
                  key: const ValueKey('formula-difference-percent'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: model.mutedTextColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              if (differenceText != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: strings.reuseResult,
                  visualDensity: VisualDensity.compact,
                  color: model.textColor1,
                  icon: const Icon(Icons.calculate_outlined, size: 20),
                  onPressed: () => _useInCalculator(difference),
                ),
              ],
            ],
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
                  '$baselineTitle: ${_resultText(baselineValue)}',
                  '$alternateTitle: ${_resultText(alternateValue)}',
                  '$differenceTitle: $differenceText',
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

  Widget _customization(S strings, Set<String> variables) {
    Widget field({
      required String key,
      required String label,
      required String? value,
      required int maxLength,
      required ValueChanged<String> onChanged,
    }) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        key: ValueKey('formula-$key'),
        initialValue: value,
        enabled: !_saving,
        maxLength: maxLength,
        decoration: InputDecoration(labelText: label, counterText: ''),
        onChanged: (value) => setState(() => onChanged(value)),
      ),
    );

    return ExpansionTile(
      title: Text(strings.formulaCustomize),
      tilePadding: EdgeInsets.zero,
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field(
          key: 'baseline-name',
          label: strings.formulaBaselineName,
          value: _baselineName,
          maxLength: FormulaStorage.maxNameLength,
          onChanged: (value) => _baselineName = value,
        ),
        field(
          key: 'alternate-name',
          label: strings.formulaAlternateName,
          value: _alternateName,
          maxLength: FormulaStorage.maxNameLength,
          onChanged: (value) => _alternateName = value,
        ),
        for (final variable in variables) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Semantics(header: true, child: Text(variable)),
          ),
          Semantics(
            hint: variable,
            child: field(
              key: 'label-$variable',
              label: strings.formulaInputLabel,
              value: _labels[variable],
              maxLength: FormulaStorage.maxInputLabelLength,
              onChanged: (value) => _labels[variable] = value,
            ),
          ),
          Semantics(
            hint: variable,
            child: field(
              key: 'unit-$variable',
              label: strings.formulaInputUnit,
              value: _units[variable],
              maxLength: FormulaStorage.maxUnitLength,
              onChanged: (value) => _units[variable] = value,
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
    final title = switch ((widget.isNew, _editing)) {
      (true, _) => strings.formulaNew,
      (_, true) => strings.formulaEdit,
      _ => _name,
    };
    return PopScope(
      canPop: !_saving,
      child: _FormulaScaffold(
        title: title,
        actions: [
          if (!_editing)
            IconButton(
              tooltip: strings.formulaEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: _saving ? null : () => setState(() => _editing = true),
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(strings.formulaSave),
          ),
        ],
        body: ListView(
          key: ValueKey(_editing),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (_editing) ...[
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
            ],
            if (variables != null && !tooManyInputs) ...[
              if (_editing) ...[
                const SizedBox(height: 12),
                _customization(strings, variables),
                const SizedBox(height: 12),
              ],
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
