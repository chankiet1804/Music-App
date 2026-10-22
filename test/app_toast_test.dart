import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/shared/widgets/toast/app_toast.dart';
import 'package:music_app/shared/widgets/toast/app_toaster.dart';
import 'package:music_app/theme/theme.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<void> _pump(WidgetTester tester) {
  return tester.pumpWidget(
    ShadApp(
      theme: AppTheme.dark,
      home: const SizedBox.expand(),
      builder: (context, child) => AppToaster(child: child!),
    ),
  );
}

double _opacityOf(WidgetTester tester, String text) {
  final opacity = find.ancestor(
    of: find.text(text),
    matching: find.byType(Opacity),
  );
  return tester.widget<Opacity>(opacity.first).opacity;
}

void main() {
  testWidgets('shows a toast and auto-dismisses it after its lifetime', (
    tester,
  ) async {
    await _pump(tester);
    AppToast.success('Saved');
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('hides toasts beyond the visible count until there is room', (
    tester,
  ) async {
    await _pump(tester);
    AppToast.show('T1');
    AppToast.show('T2');
    AppToast.show('T3');
    final newest = AppToast.show('T4');
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'T1'), 0);
    expect(_opacityOf(tester, 'T2'), 1);

    AppToast.dismiss(newest);
    await tester.pumpAndSettle();
    expect(find.text('T4'), findsNothing);
    expect(_opacityOf(tester, 'T1'), 1);
  });

  testWidgets('swiping towards the edge dismisses, a short drag snaps back', (
    tester,
  ) async {
    await _pump(tester);
    AppToast.show('Swipe me');
    await tester.pumpAndSettle();

    await tester.drag(find.text('Swipe me'), const Offset(0, -20));
    await tester.pumpAndSettle();
    expect(find.text('Swipe me'), findsOneWidget);

    await tester.drag(find.text('Swipe me'), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(find.text('Swipe me'), findsNothing);
  });

  testWidgets('horizontal swipe dismisses', (tester) async {
    await _pump(tester);
    AppToast.show('Sideways');
    await tester.pumpAndSettle();

    await tester.drag(find.text('Sideways'), const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(find.text('Sideways'), findsNothing);
  });

  testWidgets('tapping expands the stack and pauses timers', (tester) async {
    await _pump(tester);
    AppToast.show('A');
    AppToast.show('B');
    await tester.pumpAndSettle();

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);
  });

  testWidgets('tapping outside collapses the expanded stack', (tester) async {
    await _pump(tester);
    AppToast.show('A');
    AppToast.show('B');
    await tester.pumpAndSettle();

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    final expandedY = tester.getTopLeft(find.text('A')).dy;

    await tester.tapAt(const Offset(10, 500));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('A')).dy, lessThan(expandedY));
  });

  testWidgets('promise turns the loading toast into a success toast', (
    tester,
  ) async {
    await _pump(tester);
    final completer = Completer<int>();
    AppToast.promise(
      completer.future,
      loading: 'Loading',
      success: (value) => 'Done $value',
    );
    // The spinner never settles, so pump fixed frames.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Loading'), findsOneWidget);

    completer.complete(7);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Loading'), findsNothing);
    expect(find.text('Done 7'), findsOneWidget);
  });

  testWidgets('calls without a mounted toaster are no-ops', (tester) async {
    await tester.pumpWidget(const SizedBox());
    expect(() => AppToast.success('Nobody listens'), returnsNormally);
  });
}
