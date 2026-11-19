import 'dart:math' as math;

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
  final _minimum = TextEditingController(text: '-10');
  final _maximum = TextEditingController(text: '10');
  String? _compiledSource;
  ScientificGraph? _compiledFunction;
  _GraphData? _data;
  _GraphError? _error;
  GraphRootResult? _root;
  GraphPoint? _selected;

  @override
  void initState() {
    super.initState();
    if (_expression.text.trim().isNotEmpty) _updateGraph();
  }

  @override
  void dispose() {
    _expression.dispose();
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  ScientificGraph _getFunction() {
    final source = _expression.text.trim();
    if (_compiledSource != source || _compiledFunction == null) {
      final function = ScientificGraph.compile(
        source,
        degrees: widget.degrees,
        answer: widget.answer,
      );
      _compiledSource = source;
      _compiledFunction = function;
    }
    return _compiledFunction!;
  }

  void _clearOutput(String _) {
    if (_data == null && _error == null && _root == null) return;
    setState(() {
      _data = null;
      _error = null;
      _root = null;
      _selected = null;
    });
  }

  void _submit({bool findRoot = false}) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _updateGraph(findRoot: findRoot));
  }

  void _updateGraph({bool findRoot = false}) {
    _error = null;
    _root = null;
    _selected = null;
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
    try {
      function = _getFunction();
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
        previous.interval.minimum != interval.minimum ||
        previous.interval.maximum != interval.maximum) {
      _data = _GraphData(function, interval);
    }
    if (_data!.verticalRange == null) _error = _GraphError.noValues;
    if (findRoot) {
      _root = function.findRoot(interval);
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
    final data = _data;
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: foreground,
          onPrimary: model.backgroundColor,
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
                  Text(
                    widget.degrees
                        ? strings.scientificDegrees
                        : strings.scientificRadians,
                    style: TextStyle(color: foreground),
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
                    ],
                  ),
                  if (error != null || rootText != null)
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
                            : _GraphPlot(
                                data: data,
                                range: range,
                                selected: _selected,
                                root: root?.root,
                                model: model,
                                onInspect: (fraction) {
                                  final x = data.interval.position(fraction);
                                  setState(() {
                                    _selected = (
                                      x: x,
                                      y: data.function.valueAt(x),
                                    );
                                  });
                                },
                              );
                        final table = _GraphValueTable(
                          points: data.table,
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
  _GraphData(this.function, this.interval) {
    final samples = function.curve(interval);
    points = List.unmodifiable(samples);
    table = List.unmodifiable(function.valueTable(interval));
    verticalRange = _VerticalRange.forPoints(samples);
  }

  final ScientificGraph function;
  final GraphInterval interval;
  late final List<GraphPoint> points;
  late final List<GraphPoint> table;
  late final _VerticalRange? verticalRange;
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

class _GraphPlot extends StatelessWidget {
  const _GraphPlot({
    required this.data,
    required this.range,
    required this.selected,
    required this.root,
    required this.model,
    required this.onInspect,
  });

  final _GraphData data;
  final _VerticalRange range;
  final GraphPoint? selected;
  final GraphRoot? root;
  final ThemeModel model;
  final ValueChanged<double> onInspect;

  double get _inspectionFraction {
    final x = selected?.x;
    final interval = data.interval;
    return x == null ? 0.5 : (x - interval.minimum) / interval.width;
  }

  Widget _plotViewport(S strings, Color curve, Color axis) => LayoutBuilder(
    builder: (context, constraints) {
      void inspect(Offset localPosition) =>
          onInspect((localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0));
      final fraction = _inspectionFraction;
      final lower = (fraction - 0.1).clamp(0.0, 1.0);
      final higher = (fraction + 0.1).clamp(0.0, 1.0);
      void decrease() => onInspect(lower);
      void increase() => onInspect(higher);
      String descriptionAt(double position) {
        final x = data.interval.position(position);
        return _coordinateText((x: x, y: data.function.valueAt(x)), strings);
      }

      final point = selected;
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
                return MouseRegion(
                  cursor: SystemMouseCursors.precise,
                  child: GestureDetector(
                    key: const ValueKey('scientific-graph-plot'),
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      focus.requestFocus();
                      inspect(details.localPosition);
                    },
                    onHorizontalDragStart: (details) =>
                        inspect(details.localPosition),
                    onHorizontalDragUpdate: (details) =>
                        inspect(details.localPosition),
                    child: CustomPaint(
                      painter: _PlotPainter(
                        data: data,
                        range: range,
                        selected: point,
                        root: root,
                        curve: curve,
                        axis: axis,
                        focused: focus.hasPrimaryFocus,
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
    final labelStyle = TextStyle(
      color: model.panelTextColor,
      fontSize: 12,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final curve = ThemeModel.readableOn(model.panelColor, model.buttonColor2);
    final axis = model.panelTextColor.withValues(
      alpha: model.highContrastEnabled ? 0.8 : 0.7,
    );
    final point = selected;
    return DecoratedBox(
      decoration: _panelDecoration(model),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                                _axisText(range.maxValue),
                                style: labelStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _axisText(range.minValue),
                                style: labelStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(child: _plotViewport(strings, curve, axis)),
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
                    _axisText(data.interval.minimum),
                    style: labelStyle,
                  ),
                ),
                Text('x', style: labelStyle),
                Expanded(
                  child: Text(
                    _axisText(data.interval.maximum),
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
                child: SelectableText(
                  _coordinateText(point, strings),
                  style: TextStyle(color: model.panelTextColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GraphValueTable extends StatelessWidget {
  const _GraphValueTable({required this.points, required this.model});

  final List<GraphPoint> points;
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
                TableRow(children: [cell('x', heading), cell('f(x)', heading)]),
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
    required this.curve,
    required this.axis,
    required this.focused,
  });

  final _GraphData data;
  final _VerticalRange range;
  final GraphPoint? selected;
  final GraphRoot? root;
  final Color curve;
  final Color axis;
  final bool focused;

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

    final path = Path();
    final dotPaint = Paint()..color = curve;
    var penDown = false;
    for (var i = 0; i < data.points.length; i++) {
      final point = data.points[i];
      final y = point.y;
      if (y == null) {
        penDown = false;
        continue;
      }
      if (penDown) {
        path.lineTo(toX(point.x), toY(y));
      } else {
        path.moveTo(toX(point.x), toY(y));
        if (i + 1 == data.points.length || data.points[i + 1].y == null) {
          canvas.drawCircle(Offset(toX(point.x), toY(y)), 2, dotPaint);
        }
        penDown = true;
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = curve
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2.25,
    );

    final marker = selected;
    if (marker != null) {
      final x = toX(marker.x);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), axisPaint);
      final y = marker.y;
      if (y != null) {
        canvas.drawCircle(Offset(x, toY(y)), 4, dotPaint);
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
      curve != oldDelegate.curve ||
      axis != oldDelegate.axis ||
      focused != oldDelegate.focused;
}
