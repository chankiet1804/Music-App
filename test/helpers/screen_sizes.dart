import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class ScreenSize {
  const ScreenSize(this.name, this.size, {this.textScale = 1.0});

  final String name;

  /// Logical size in dp (applied with devicePixelRatio 1).
  final Size size;
  final double textScale;

  @override
  String toString() => name;
}

const screenSizes = [
  ScreenSize('small phone', Size(320, 568)),
  ScreenSize('phone', Size(393, 852)),
  ScreenSize('large phone', Size(430, 932)),
  ScreenSize('landscape', Size(852, 393)),
  ScreenSize('tablet', Size(820, 1180)),
  ScreenSize('large text', Size(393, 852), textScale: 2.0),
];

/// Applies [screen] to the test view and resets it on teardown.
void setScreenSize(WidgetTester tester, ScreenSize screen) {
  tester.view.physicalSize = screen.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = screen.textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Runs [body] once per entry in [screenSizes]. Layout overflow fails the
/// test on its own, so [body] only needs to pump the screen.
void testWidgetsOnScreens(
  String description,
  Future<void> Function(WidgetTester tester, ScreenSize screen) body,
) {
  for (final screen in screenSizes) {
    testWidgets('$description [$screen]', (tester) => body(tester, screen));
  }
}
