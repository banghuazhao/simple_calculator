import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/premium/scientific_graph.dart';
import 'package:simple_calculator/premium/scientific_graph_page.dart';
import 'package:simple_calculator/util/theme_model.dart';

void main() {
  ScientificGraph compile(String source, {bool degrees = true, double? ans}) =>
      ScientificGraph.compile(source, degrees: degrees, answer: ans);

  GraphInterval interval(double minimum, double maximum) =>
      GraphInterval.tryCreate(minimum, maximum)!;

  group('scientific graph model', () {
    test('evaluates x, preserves angle mode and binds a previous answer', () {
      expect(
        compile('sin(X) + aNs', ans: 0.1).valueAt(30),
        closeTo(0.6, 1e-15),
      );
      expect(compile('sin(x)', degrees: false).valueAt(math.pi / 2), 1);
      expect(() => compile('x + Ans'), throwsA(isA<GraphVariablesException>()));
      expect(() => compile('x + y'), throwsA(isA<GraphVariablesException>()));
      expect(GraphInterval.tryCreate(double.nan, 2), isNull);
      expect(GraphInterval.tryCreate(2, 2), isNull);
      expect(GraphInterval.tryCreate(-1.7e308, 1.7e308), isNull);
    });

    test(
      'keeps undefined values and separates the curve at off-grid poles',
      () {
        final squareRoot = compile('sqrt(x)');
        final table = squareRoot.valueTable(interval(-5, 5));
        expect(table.first, (x: -5.0, y: null));
        expect(table[5], (x: 0.0, y: 0.0));
        expect(table.last.y, closeTo(math.sqrt(5), 1e-15));
        final points = compile('1 / (x - 0.12345)').curve(interval(-1, 1));
        expect(
          points.any(
            (point) => point.x > 0.11 && point.x < 0.13 && point.y == null,
          ),
          isTrue,
        );
      },
    );

    test('verifies an interior numerical root and an exact endpoint', () {
      final quadratic = compile('x^2 - 2');
      final solution = quadratic.findRoot(interval(0, 2));
      expect(solution.status, GraphRootStatus.found);
      expect(solution.root!.x, closeTo(math.sqrt(2), 1e-14));
      expect(solution.root!.y, closeTo(0, 1e-14));
      expect(compile('x - 2').findRoot(interval(2, 5)).root, (x: 2.0, y: 0.0));
      expect(
        quadratic.findRoot(interval(-2, 2)).status,
        GraphRootStatus.needsBracket,
      );
      expect(compile('x - 1e-100').findRoot(interval(0, 1)).root, (
        x: 1e-100,
        y: 0.0,
      ));
    });

    test('rejects false roots at holes, leaps and scaled poles', () {
      for (final source in [
        '1 / x',
        '1e-200 / (x - 0.12345)',
        'abs(x - 0.12345) / (x - 0.12345)',
        'tan(x)',
      ]) {
        final limits = source == 'tan(x)' ? interval(80, 100) : interval(-1, 1);
        expect(
          compile(source).findRoot(limits).status,
          GraphRootStatus.unverified,
          reason: source,
        );
      }
      final scaled = compile('1e-200 * (x^2 - 2)').findRoot(interval(0, 2));
      expect(scaled.root!.x, closeTo(math.sqrt(2), 1e-14));
    });
  });

  Future<S> pumpGraph(WidgetTester tester, {String source = ''}) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeModel(),
        child: MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: ScientificGraphPage(initialExpression: source),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return S.of(tester.element(find.byType(ScientificGraphPage)));
  }

  const plotKey = ValueKey('scientific-graph-plot');
  testWidgets('plots, inspects values and finds a root on a narrow phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final strings = await pumpGraph(tester);
    final plot = find.byKey(plotKey);
    final expression = find.widgetWithText(TextField, 'f(x)');
    final minimum = find.widgetWithText(TextField, strings.graphXMin);
    final maximum = find.widgetWithText(TextField, strings.graphXMax);
    expect(plot, findsNothing);
    await tester.enterText(expression, 'x^2 - 2');
    await tester.enterText(minimum, '0');
    await tester.enterText(maximum, '2');
    await tester.tap(find.text(strings.graphPlot));
    await tester.pumpAndSettle();

    expect(plot, findsOneWidget);
    await tester.tap(plot);
    await tester.pumpAndSettle();
    expect(find.text('x = 1    f(x) = -1'), findsOneWidget);
    expect(find.text(strings.graphValueTable), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('x = 1.2    f(x) = -0.56'), findsOneWidget);

    await tester.tap(find.text(strings.graphFindRoot));
    await tester.pumpAndSettle();
    expect(find.text(strings.graphRootResult), findsOneWidget);
    expect(find.textContaining('x ≈ 1.414213562373'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'prefills the graph, lays out the table beside it, and validates bounds',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 840));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final strings = await pumpGraph(tester, source: 'x + 1');
      final plot = find.byKey(plotKey);
      final table = find.text(strings.graphValueTable);
      expect(plot, findsOneWidget);
      expect(
        tester.getTopLeft(table).dx,
        greaterThan(tester.getTopRight(plot).dx),
      );

      await tester.enterText(
        find.widgetWithText(TextField, strings.graphXMin),
        '20',
      );
      await tester.tap(find.text(strings.graphFindRoot));
      await tester.pumpAndSettle();
      expect(find.text(strings.graphInvalidRange), findsOneWidget);
      expect(plot, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
