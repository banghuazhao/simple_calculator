import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/premium/expression_engine.dart';
import 'package:simple_calculator/premium/scientific_graph.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/theme_model.dart';

class ScientificGraphPage extends StatefulWidget {
  const ScientificGraphPage({
    super.key,
    this.initialExpression = '',
    this.degrees = true,
    this.answer,
  });

  final String initialExpression;
  final bool degrees;
  final double? answer;

  @override
  State<ScientificGraphPage> createState() => _ScientificGraphPageState();
}

enum _GraphError { expression, variables, interval, noValues }

class _ScientificGraphPageState extends State<ScientificGraphPage> {
  late final _expression = TextEditingController(
    text: widget.initialExpression,
  );
  final _secondExpression = TextEditingController();
  final _minimum = TextEditingController(text: '-10');
  final _maximum = TextEditingController(text: '10');
  late bool _degrees = widget.degrees;
  String? _compiledSource;
  bool? _compiledDegrees;
  ScientificGraph? _compiledFunction;
  String? _compiledSecondSource;
  ScientificGraph? _compiledSecondFunction;
  _GraphData? _data;
  _GraphError? _error;
  GraphRootResult? _root;
  GraphRootResult? _intersection;
  GraphPoint? _selected;
  double? _selectedSecondY;

  @override
  void initState() {
    super.initState();
    if (_expression.text.trim().isNotEmpty) _updateGraph();
  }

  @override
  void dispose() {
    _expression.dispose();
    _secondExpression.dispose();
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  ScientificGraph _getFunction() {
    final source = _expression.text.trim();
    if (_compiledSource != source ||
        _compiledDegrees != _degrees ||
        _compiledFunction == null) {
      final function = ScientificGraph.compile(
        source,
        degrees: _degrees,
        answer: widget.answer,
      );
      _compiledSource = source;
      _compiledDegrees = _degrees;
      _compiledFunction = function;
    }
    return _compiledFunction!;
  }

  ScientificGraph? _getSecondFunction() {
    final source = _secondExpression.text.trim();
    if (source.isEmpty) {
      _compiledSecondSource = null;
      _compiledSecondFunction = null;
      return null;
    }
    if (_compiledSecondSource != source ||
        _compiledDegrees != _degrees ||
        _compiledSecondFunction == null) {
      final function = ScientificGraph.compile(
        source,
        degrees: _degrees,
        answer: widget.answer,
      );
      _compiledSecondSource = source;
      _compiledSecondFunction = function;
    }
    return _compiledSecondFunction;
  }

  void _clearOutput(String _) {
    if (_data == null &&
        _error == null &&
        _root == null &&
        _intersection == null) {
      return;
    }
    setState(() {
      _data = null;
      _error = null;
      _root = null;
      _intersection = null;
      _selected = null;
      _selectedSecondY = null;
    });
  }

  void _setDegrees(bool degrees) {
    if (_degrees == degrees) return;
    setState(() {
      _degrees = degrees;
      _compiledFunction = null;
      _compiledSecondFunction = null;
      if (_data != null) {
        _updateGraph();
      }
    });
  }

  void _zoom(double factor) {
    final current = _data?.interval;
    if (current == null) return;
    final center = (current.minimum + current.maximum) / 2;
    final half = (current.width / 2) * factor;
    if (!half.isFinite || half <= 0) return;
    final nextMin = center - half;
    final nextMax = center + half;
    if (GraphInterval.tryCreate(nextMin, nextMax) == null) return;
    _minimum.text = Processor.formatResult(nextMin);
    _maximum.text = Processor.formatResult(nextMax);
    setState(() => _updateGraph());
  }

  void _panByFraction(double deltaFraction) {
    final current = _data?.interval;
    if (current == null) return;
    final shift = current.width * deltaFraction;
    final nextMin = current.minimum + shift;
    final nextMax = current.maximum + shift;
    if (GraphInterval.tryCreate(nextMin, nextMax) == null) return;
    _minimum.text = Processor.formatResult(nextMin);
    _maximum.text = Processor.formatResult(nextMax);
    setState(() => _updateGraph());
  }

  void _resetView() {
    _minimum.text = '-10';
    _maximum.text = '10';
    setState(() => _updateGraph());
  }

  void _submit({bool findRoot = false, bool findIntersection = false}) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(
      () => _updateGraph(
        findRoot: findRoot,
        findIntersection: findIntersection,
      ),
    );
  }

  void _updateGraph({bool findRoot = false, bool findIntersection = false}) {
    _error = null;
    _root = null;
    _intersection = null;
    _selected = null;
    _selectedSecondY = null;
    final interval = GraphInterval.tryCreate(
      Processor.parseNumericInput(_minimum.text),
      Processor.parseNumericInput(_maximum.text),
    );
    if (interval == null) {
      _data = null;
      _error = _GraphError.interval;
      return;
    }
    final ScientificGraph function;
    final ScientificGraph? secondFunction;
    try {
      function = _getFunction();
      secondFunction = _getSecondFunction();
    } on GraphVariablesException {
      _data = null;
      _error = _GraphError.variables;
      return;
    } on FormatException {
      _data = null;
      _error = _GraphError.expression;
      return;
    }
    final previous = _data;
    if (previous == null ||
        previous.function != function ||
        previous.secondFunction != secondFunction ||
        previous.interval.minimum != interval.minimum ||
        previous.interval.maximum != interval.maximum) {
      _data = _GraphData(function, interval, secondFunction: secondFunction);
    }
    if (_data!.verticalRange == null) _error = _GraphError.noValues;
    if (findRoot) {
      _root = function.findRoot(interval);
    }
    if (findIntersection && secondFunction != null) {
      _intersection = function.findIntersection(secondFunction, interval);
    }
  }

  Widget _boundField(String label, TextEditingController controller) =>
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        textInputAction: TextInputAction.done,
        inputFormatters: [LengthLimitingTextInputFormatter(64)],
        decoration: InputDecoration(labelText: label),
        onChanged: _clearOutput,
        onSubmitted: (_) => _submit(),
      );

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final model = context.watch<ThemeModel>();
    final foreground = model.readableTextColor;
    final error = switch (_error) {
      _GraphError.expression => strings.scientificInvalidExpression,
      _GraphError.variables => strings.graphInvalidVariables,
      _GraphError.interval => strings.graphInvalidRange,
      _GraphError.noValues => strings.graphNoValues,
      null => null,
    };
    final root = _root;
    final rootText = switch (root?.status) {
      GraphRootStatus.found => _coordinateText(
        root!.root!,
        strings,
        root: true,
      ),
      GraphRootStatus.needsBracket => strings.graphRootNeedsBracket,
      GraphRootStatus.unverified => strings.graphRootNotFound,
      null => null,
    };
    final intersection = _intersection;
    final intersectionText = switch (intersection?.status) {
      GraphRootStatus.found => _coordinateText(
        intersection!.root!,
        strings,
        root: true,
      ),
      GraphRootStatus.needsBracket ||
      GraphRootStatus.unverified => strings.graphIntersectionNotFound,
      null => null,
    };
    final hasSecond = _secondExpression.text.trim().isNotEmpty;
    final data = _data;
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: foreground,
          onPrimary: model.backgroundColor,
          secondaryContainer: foreground,
          onSecondaryContainer: model.backgroundColor,
          surface: model.backgroundColor,
          onSurface: foreground,
          onSurfaceVariant: foreground,
          outline: foreground,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      child: Scaffold(
        backgroundColor: model.backgroundColor,
        appBar: AppBar(
          title: Text(strings.scientificGraph),
          backgroundColor: model.backgroundColor,
          foregroundColor: foreground,
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1024),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  TextField(
                    controller: _expression,
                    autocorrect: false,
                    enableSuggestions: false,
                    smartDashesType: SmartDashesType.disabled,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        ExpressionEngine.maxLength,
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'f(x)',
                      helperText: strings.graphExpressionHelp,
                      helperMaxLines: 3,
                      suffixIcon: IconButton(
                        tooltip: strings.clearInput,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _expression.clear();
                          _clearOutput('');
                        },
                      ),
                    ),
                    onChanged: _clearOutput,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('graph-second-expression'),
                    controller: _secondExpression,
                    autocorrect: false,
                    enableSuggestions: false,
                    smartDashesType: SmartDashesType.disabled,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        ExpressionEngine.maxLength,
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: strings.graphSecondFunction,
                      suffixIcon: _secondExpression.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: strings.clearInput,
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _secondExpression.clear();
                                setState(() {});
                                _clearOutput('');
                              },
                            ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      _clearOutput(value);
                    },
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final minimum = _boundField(strings.graphXMin, _minimum);
                      final maximum = _boundField(strings.graphXMax, _maximum);
                      if (constraints.maxWidth < 300 ||
                          MediaQuery.textScalerOf(context).scale(16) > 27) {
                        return Column(
                          children: [
                            minimum,
                            const SizedBox(height: 12),
                            maximum,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: minimum),
                          const SizedBox(width: 12),
                          Expanded(child: maximum),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(strings.scientificDegrees),
                        selected: _degrees,
                        onSelected: (_) => _setDegrees(true),
                      ),
                      ChoiceChip(
                        label: Text(strings.scientificRadians),
                        selected: !_degrees,
                        onSelected: (_) => _setDegrees(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: _submit,
                        icon: const Icon(Icons.show_chart),
                        label: Text(strings.graphPlot),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          side: BorderSide(color: foreground),
                        ),
                        onPressed: () => _submit(findRoot: true),
                        icon: const Icon(Icons.adjust),
                        label: Text(strings.graphFindRoot),
                      ),
                      if (hasSecond)
                        OutlinedButton.icon(
                          key: const ValueKey('graph-find-intersection'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            side: BorderSide(color: foreground),
                          ),
                          onPressed: () => _submit(findIntersection: true),
                          icon: const Icon(Icons.join_inner),
                          label: Text(strings.graphFindIntersection),
                        ),
                    ],
                  ),
                  if (error != null ||
                      rootText != null ||
                      intersectionText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (error != null)
                              Text(error, style: TextStyle(color: foreground)),
                            if (root?.root != null)
                              Text(
                                strings.graphRootResult,
                                style: TextStyle(
                                  color: foreground,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (rootText != null)
                              SelectableText(
                                rootText,
                                style: TextStyle(color: foreground),
                              ),
                            if (intersection?.root != null)
                              Text(
                                strings.graphIntersectionResult,
                                style: TextStyle(
                                  color: foreground,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (intersectionText != null)
                              SelectableText(
                                intersectionText,
                                style: TextStyle(color: foreground),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (data != null) ...[
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final range = data.verticalRange;
                        final plot = range == null
                            ? null
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _GraphPlot(
                                    data: data,
                                    range: range,
                                    selected: _selected,
                                    selectedSecondY: _selectedSecondY,
                                    root: root?.root,
                                    intersection: intersection?.root,
                                    model: model,
                                    onZoomIn: () => _zoom(0.5),
                                    onZoomOut: () => _zoom(2.0),
                                    onReset: _resetView,
                                    onZoomFactor: _zoom,
                                    onPanFraction: _panByFraction,
                                    onInspect: (fraction) {
                                      final x = data.interval.position(
                                        fraction,
                                      );
                                      setState(() {
                                        _selected = (
                                          x: x,
                                          y: data.function.valueAt(x),
                                        );
                                        _selectedSecondY = data.secondFunction
                                            ?.valueAt(x);
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _GraphKeyPoints(data: data, model: model),
                                ],
                              );
                        final table = _GraphValueTable(
                          points: data.table,
                          secondFunction: data.secondFunction,
                          model: model,
                        );
                        if (plot == null) return table;
                        if (constraints.maxWidth >= 760) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: plot),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: table),
                            ],
                          );
                        }
                        return Column(
                          children: [plot, const SizedBox(height: 16), table],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _coordinateText(GraphPoint point, S strings, {bool root = false}) {
  final x = Processor.formatResult(point.x);
  final y = point.y;
  final value = y == null ? strings.graphUndefined : Processor.formatResult(y);
  return root ? 'x ≈ $x    f(x) ≈ $value' : 'x = $x    f(x) = $value';
}

class _GraphData {
  _GraphData(this.function, this.interval, {this.secondFunction}) {
    final samples = function.curve(interval);
    points = List.unmodifiable(samples);
    secondPoints = secondFunction == null
        ? const []
        : List.unmodifiable(secondFunction!.curve(interval));
    table = List.unmodifiable(function.valueTable(interval));
    verticalRange = _VerticalRange.forPoints([...samples, ...secondPoints]);
    yIntercept = function.yIntercept(interval);
    final ext = ScientificGraph.extrema(samples);
    minimumPoint = ext.min;
    maximumPoint = ext.max;
  }

  final ScientificGraph function;
  final ScientificGraph? secondFunction;
  final GraphInterval interval;
  late final List<GraphPoint> points;
  late final List<GraphPoint> secondPoints;
  late final List<GraphPoint> table;
  late final _VerticalRange? verticalRange;
  late final double? yIntercept;
  late final GraphPoint? minimumPoint;
  late final GraphPoint? maximumPoint;
}

class _VerticalRange {
  const _VerticalRange(this.scale, this.minimum, this.maximum);

  final double scale;
  final double minimum;
  final double maximum;

  double get width => maximum - minimum;
  double get maxValue => maximum * scale;
  double get minValue => minimum * scale;

  double fraction(double y) => (y / scale - minimum) / width;

  static _VerticalRange? forPoints(List<GraphPoint> points) {
    final values = points.map((point) => point.y).nonNulls.toList()..sort();
    if (values.isEmpty) return null;
    final maximumMagnitude = math.max(values.first.abs(), values.last.abs());
    final scale = maximumMagnitude == 0 ? 1.0 : maximumMagnitude;
    var low = values.first / scale;
    var high = values.last / scale;

    // Keep most of a curve visible when a handful of samples approach a pole.
    final trim = values.length ~/ 50;
    if (trim > 0) {
      final coreLow = values[trim] / scale;
      final coreHigh = values[values.length - trim - 1] / scale;
      final coreWidth = coreHigh - coreLow;
      if (coreWidth > 0 && high - low > coreWidth * 8) {
        low = coreLow;
        high = coreHigh;
      }
    }

    final padding = high == low ? 0.15 : (high - low) * 0.05;
    return _VerticalRange(scale, low - padding, high + padding);
  }
}

class _GraphKeyPoints extends StatelessWidget {
  const _GraphKeyPoints({required this.data, required this.model});

  final _GraphData data;
  final ThemeModel model;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final style = TextStyle(
      color: model.panelTextColor,
      fontSize: 13,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final items = <String>[
      if (data.yIntercept != null)
        '${strings.graphYIntercept}: (0, ${Processor.formatResult(data.yIntercept!)})',
      if (data.minimumPoint case final min?)
        '${strings.graphMinimum}: (${Processor.formatResult(min.x)}, ${Processor.formatResult(min.y!)})',
      if (data.maximumPoint case final max?)
        '${strings.graphMaximum}: (${Processor.formatResult(max.x)}, ${Processor.formatResult(max.y!)})',
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: _panelDecoration(model),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.graphKeyPoints,
              style: style.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: SelectableText(item, style: style),
              ),
          ],
        ),
      ),
    );
  }
}

class _GraphPlot extends StatefulWidget {
  const _GraphPlot({
    required this.data,
    required this.range,
    required this.selected,
    required this.selectedSecondY,
    required this.root,
    required this.intersection,
    required this.model,
    required this.onInspect,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.onZoomFactor,
    required this.onPanFraction,
  });

  final _GraphData data;
  final _VerticalRange range;
  final GraphPoint? selected;
  final double? selectedSecondY;
  final GraphRoot? root;
  final GraphRoot? intersection;
  final ThemeModel model;
  final ValueChanged<double> onInspect;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final ValueChanged<double> onZoomFactor;
  final ValueChanged<double> onPanFraction;

  @override
  State<_GraphPlot> createState() => _GraphPlotState();
}

class _GraphPlotState extends State<_GraphPlot> {
  final Map<int, Offset> _pointers = {};
  double? _lastPinchSpan;
  Offset? _lastPinchCenter;

  double get _inspectionFraction {
    final x = widget.selected?.x;
    final interval = widget.data.interval;
    return x == null ? 0.5 : (x - interval.minimum) / interval.width;
  }

  Widget _plotViewport(
    S strings,
    Color curve,
    Color secondCurve,
    Color axis,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      void inspect(Offset localPosition) => widget.onInspect(
        (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0),
      );
      final fraction = _inspectionFraction;
      final lower = (fraction - 0.1).clamp(0.0, 1.0);
      final higher = (fraction + 0.1).clamp(0.0, 1.0);
      void decrease() => widget.onInspect(lower);
      void increase() => widget.onInspect(higher);
      String descriptionAt(double position) {
        final x = widget.data.interval.position(position);
        return _coordinateText(
          (x: x, y: widget.data.function.valueAt(x)),
          strings,
        );
      }

      final point = widget.selected;
      return Semantics(
        label: strings.scientificGraph,
        value: point == null
            ? descriptionAt(fraction)
            : _coordinateText(point, strings),
        slider: true,
        decreasedValue: descriptionAt(lower),
        increasedValue: descriptionAt(higher),
        onDecrease: fraction > 0 ? decrease : null,
        onIncrease: fraction < 1 ? increase : null,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowLeft): decrease,
            const SingleActivator(LogicalKeyboardKey.arrowRight): increase,
          },
          child: Focus(
            child: Builder(
              builder: (context) {
                final focus = Focus.of(context);
                return Listener(
                  onPointerDown: (event) {
                    _pointers[event.pointer] = event.localPosition;
                    if (_pointers.length == 2) {
                      final pts = _pointers.values.toList();
                      _lastPinchSpan = (pts[0] - pts[1]).distance;
                      _lastPinchCenter = (pts[0] + pts[1]) / 2;
                    }
                  },
                  onPointerMove: (event) {
                    if (!_pointers.containsKey(event.pointer)) return;
                    _pointers[event.pointer] = event.localPosition;
                    if (_pointers.length == 2) {
                      final pts = _pointers.values.toList();
                      final span = (pts[0] - pts[1]).distance;
                      final center = (pts[0] + pts[1]) / 2;
                      final prevSpan = _lastPinchSpan;
                      final prevCenter = _lastPinchCenter;
                      if (prevSpan != null && prevSpan > 10 && span > 10) {
                        final ratio = prevSpan / span;
                        if ((ratio - 1).abs() > 0.04) {
                          widget.onZoomFactor(ratio.clamp(0.5, 2.0));
                          _lastPinchSpan = span;
                        }
                      }
                      if (prevCenter != null && constraints.maxWidth > 0) {
                        final dx = center.dx - prevCenter.dx;
                        if (dx.abs() > 8) {
                          widget.onPanFraction(-dx / constraints.maxWidth);
                          _lastPinchCenter = center;
                        }
                      }
                    }
                  },
                  onPointerUp: (event) {
                    _pointers.remove(event.pointer);
                    if (_pointers.length < 2) {
                      _lastPinchSpan = null;
                      _lastPinchCenter = null;
                    }
                  },
                  onPointerCancel: (event) {
                    _pointers.remove(event.pointer);
                    if (_pointers.length < 2) {
                      _lastPinchSpan = null;
                      _lastPinchCenter = null;
                    }
                  },
                  onPointerSignal: (signal) {
                    if (signal is PointerScrollEvent) {
                      final factor = signal.scrollDelta.dy > 0 ? 1.2 : 0.8;
                      widget.onZoomFactor(factor);
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.precise,
                    child: GestureDetector(
                      key: const ValueKey('scientific-graph-plot'),
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        if (_pointers.length >= 2) return;
                        focus.requestFocus();
                        inspect(details.localPosition);
                      },
                      onHorizontalDragStart: (details) {
                        if (_pointers.length >= 2) return;
                        inspect(details.localPosition);
                      },
                      onHorizontalDragUpdate: (details) {
                        if (_pointers.length >= 2) return;
                        inspect(details.localPosition);
                      },
                      child: CustomPaint(
                        painter: _PlotPainter(
                          data: widget.data,
                          range: widget.range,
                          selected: point,
                          root: widget.root,
                          intersection: widget.intersection,
                          curve: curve,
                          secondCurve: secondCurve,
                          axis: axis,
                          focused: focus.hasPrimaryFocus,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );

  String _axisText(double number) {
    if (number == 0) return '0';
    if (!number.isFinite) return number.isNegative ? '−∞' : '∞';
    final text = number.toStringAsPrecision(5);
    final rounded = double.parse(text);
    return rounded.isFinite ? Processor.formatResult(rounded) : text;
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final model = widget.model;
    final labelStyle = TextStyle(
      color: model.panelTextColor,
      fontSize: 12,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final curve = ThemeModel.readableOn(model.panelColor, model.buttonColor2);
    final secondCurve = ThemeModel.readableOn(
      model.panelColor,
      model.buttonColor3,
    );
    final axis = model.panelTextColor.withValues(
      alpha: model.highContrastEnabled ? 0.8 : 0.7,
    );
    final point = widget.selected;
    final secondY = widget.selectedSecondY;
    return DecoratedBox(
      decoration: _panelDecoration(model),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: strings.graphZoomIn,
                  visualDensity: VisualDensity.compact,
                  color: model.panelTextColor,
                  icon: const Icon(Icons.zoom_in, size: 20),
                  onPressed: widget.onZoomIn,
                ),
                IconButton(
                  tooltip: strings.graphZoomOut,
                  visualDensity: VisualDensity.compact,
                  color: model.panelTextColor,
                  icon: const Icon(Icons.zoom_out, size: 20),
                  onPressed: widget.onZoomOut,
                ),
                IconButton(
                  tooltip: strings.graphResetView,
                  visualDensity: VisualDensity.compact,
                  color: model.panelTextColor,
                  icon: const Icon(Icons.restart_alt, size: 20),
                  onPressed: widget.onReset,
                ),
              ],
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final height = (constraints.maxWidth * 0.58).clamp(
                  165.0,
                  320.0,
                );
                final tickWidth = math.min(constraints.maxWidth * 0.26, 88.0);
                return SizedBox(
                  height: height,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: tickWidth,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _axisText(widget.range.maxValue),
                                style: labelStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _axisText(widget.range.minValue),
                                style: labelStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: _plotViewport(strings, curve, secondCurve, axis),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _axisText(widget.data.interval.minimum),
                    style: labelStyle,
                  ),
                ),
                Text('x', style: labelStyle),
                Expanded(
                  child: Text(
                    _axisText(widget.data.interval.maximum),
                    style: labelStyle,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (point == null)
              Text(
                strings.graphPlotHint,
                style: TextStyle(color: model.panelTextColor),
              )
            else
              Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      _coordinateText(point, strings),
                      style: TextStyle(color: model.panelTextColor),
                    ),
                    if (widget.data.secondFunction != null)
                      SelectableText(
                        'g(x) = ${secondY == null ? strings.graphUndefined : Processor.formatResult(secondY)}',
                        style: TextStyle(color: model.panelTextColor),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GraphValueTable extends StatelessWidget {
  const _GraphValueTable({
    required this.points,
    required this.model,
    this.secondFunction,
  });

  final List<GraphPoint> points;
  final ScientificGraph? secondFunction;
  final ThemeModel model;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final paneText = TextStyle(color: model.panelTextColor);
    final cellStyle = paneText.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final heading = cellStyle.copyWith(fontWeight: FontWeight.w600);
    Widget cell(String text, TextStyle style) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(text, style: style, textAlign: TextAlign.end),
    );
    final second = secondFunction;
    return DecoratedBox(
      decoration: _panelDecoration(model),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
            child: Semantics(
              header: true,
              child: Text(strings.graphValueTable, style: heading),
            ),
          ),
          SelectionArea(
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: model.panelBorderColor),
              ),
              children: [
                TableRow(
                  children: [
                    cell('x', heading),
                    cell('f(x)', heading),
                    if (second != null) cell('g(x)', heading),
                  ],
                ),
                for (final point in points)
                  TableRow(
                    children: [
                      cell(Processor.formatResult(point.x), cellStyle),
                      cell(
                        point.y == null
                            ? strings.graphUndefined
                            : Processor.formatResult(point.y!),
                        cellStyle,
                      ),
                      if (second != null)
                        Builder(
                          builder: (_) {
                            final gy = second.valueAt(point.x);
                            return cell(
                              gy == null
                                  ? strings.graphUndefined
                                  : Processor.formatResult(gy),
                              cellStyle,
                            );
                          },
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration(ThemeModel model) => BoxDecoration(
  color: model.panelColor,
  border: Border.all(color: model.panelBorderColor),
  borderRadius: BorderRadius.circular(16),
);

class _PlotPainter extends CustomPainter {
  const _PlotPainter({
    required this.data,
    required this.range,
    required this.selected,
    required this.root,
    required this.intersection,
    required this.curve,
    required this.secondCurve,
    required this.axis,
    required this.focused,
  });

  final _GraphData data;
  final _VerticalRange range;
  final GraphPoint? selected;
  final GraphRoot? root;
  final GraphRoot? intersection;
  final Color curve;
  final Color secondCurve;
  final Color axis;
  final bool focused;

  void _paintCurve(
    Canvas canvas,
    Size size,
    List<GraphPoint> points,
    Color color,
    double Function(double) toX,
    double Function(double) toY, {
    double strokeWidth = 2.25,
  }) {
    if (points.isEmpty) return;
    final path = Path();
    final dotPaint = Paint()..color = color;
    var penDown = false;
    double? prevScreenY;
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final y = point.y;
      if (y == null) {
        penDown = false;
        prevScreenY = null;
        continue;
      }
      final sx = toX(point.x);
      final sy = toY(y);
      // Break across steep vertical asymptote jumps rather than connecting them.
      final hugeJump =
          prevScreenY != null && (sy - prevScreenY).abs() > size.height * 1.15;
      if (penDown && !hugeJump) {
        path.lineTo(sx, sy);
      } else {
        path.moveTo(sx, sy);
        if (i + 1 == points.length || points[i + 1].y == null) {
          canvas.drawCircle(Offset(sx, sy), 2, dotPaint);
        }
        penDown = true;
      }
      prevScreenY = sy;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final gridPaint = Paint()
      ..color = axis.withValues(alpha: axis.a * 0.38)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = axis
      ..strokeWidth = 1;
    double toX(double x) =>
        (x - data.interval.minimum) / data.interval.width * size.width;
    double toY(double y) =>
        (1 - range.fraction(y)).clamp(-2.0, 3.0) * size.height;
    canvas.save();
    canvas.clipRect(rect);
    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      final y = size.height * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (data.interval.minimum < 0 && data.interval.maximum > 0) {
      final x = toX(0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), axisPaint);
    }
    if (range.minimum < 0 && range.maximum > 0) {
      final y = toY(0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
    }

    _paintCurve(canvas, size, data.points, curve, toX, toY);
    if (data.secondPoints.isNotEmpty) {
      _paintCurve(
        canvas,
        size,
        data.secondPoints,
        secondCurve,
        toX,
        toY,
        strokeWidth: 2.0,
      );
    }

    final dotPaint = Paint()..color = curve;
    final marker = selected;
    if (marker != null) {
      final x = toX(marker.x);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), axisPaint);
      final y = marker.y;
      if (y != null) {
        canvas.drawCircle(Offset(x, toY(y)), 4, dotPaint);
      }
      final gY = data.secondFunction?.valueAt(marker.x);
      if (gY != null) {
        canvas.drawCircle(
          Offset(x, toY(gY)),
          4,
          Paint()..color = secondCurve,
        );
      }
    }
    final zero = root;
    if (zero != null) {
      canvas.drawCircle(
        Offset(toX(zero.x), toY(zero.y)),
        6,
        Paint()
          ..color = curve
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final inter = intersection;
    if (inter != null) {
      canvas.drawCircle(
        Offset(toX(inter.x), toY(inter.y)),
        7,
        Paint()
          ..color = secondCurve
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    canvas.restore();
    final borderWidth = focused ? 2.0 : 1.0;
    canvas.drawRect(
      rect.deflate(borderWidth / 2),
      axisPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(_PlotPainter oldDelegate) =>
      data != oldDelegate.data ||
      range != oldDelegate.range ||
      selected != oldDelegate.selected ||
      root != oldDelegate.root ||
      intersection != oldDelegate.intersection ||
      curve != oldDelegate.curve ||
      secondCurve != oldDelegate.secondCurve ||
      axis != oldDelegate.axis ||
      focused != oldDelegate.focused;
}
