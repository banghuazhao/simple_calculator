import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/display.dart';
import 'package:simple_calculator/main.dart';
import 'package:simple_calculator/util/storage_manager.dart';

void main() {
  testWidgets('calculator stays usable in tablet landscape and compact windows',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(800, 600));
    await tester.pumpWidget(const CalculatorApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (final size in const [
      Size(1200, 700),
      Size(500, 800),
      Size(320, 568)
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Window size $size');
      expect(tester.getBottomRight(find.text('=')).dy, lessThan(size.height));
    }

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();
    expect(tester.widget<Display>(find.byType(Display)).current, '3');
  });
}
