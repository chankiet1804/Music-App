import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/core/auth/auth_providers.dart';
import 'package:music_app/ui/login/login.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'fakes/fake_auth_service.dart';

void main() {
  testWidgets('diag', (tester) async {
    final service = FakeAuthService();
    addTearDown(service.dispose);
    // Pixel 7a: 1080x2400 @ 2.625.
    tester.view.physicalSize = const Size(2100, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(service)],
        child: const ShadApp(home: LoginPage()),
      ),
    );
    for (final kb in [0.0, 800.0, 1000.0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: kb);
      await tester.pumpAndSettle();
      final fb = tester.renderObject<RenderBox>(find.byType(FittedBox).first);
      final img = find.byType(Image).first;
      final r = tester.getRect(img);
      final viewport = tester.renderObject<RenderBox>(
        find.byType(Scrollable).first,
      );
      // ignore: avoid_print
      print(
        'kb=$kb fittedBox=${fb.size} logoRect=$r viewport=${viewport.size} '
        'scrollable=${tester.state<ScrollableState>(find.byType(Scrollable).first).position.maxScrollExtent}',
      );
    }
  });
}
