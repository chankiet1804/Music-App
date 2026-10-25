import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/core/auth/auth_providers.dart';
import 'package:music_app/data/model/auth_failure.dart';
import 'package:music_app/shared/widgets/toast/app_toaster.dart';
import 'package:music_app/theme/theme.dart';
import 'package:music_app/ui/login/login.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'fakes/fake_auth_service.dart';
import 'helpers/screen_sizes.dart';

const _email = Key('login.email');
const _password = Key('login.password');
const _confirm = Key('login.confirm');
const _submit = Key('login.submit');
const _toggle = Key('login.toggle');

Future<FakeAuthService> _pump(
  WidgetTester tester, {
  ScreenSize? screen,
}) async {
  final service = FakeAuthService();
  addTearDown(service.dispose);
  if (screen != null) {
    setScreenSize(tester, screen);
  } else {
    // Tall surface so the whole scrollable form is laid out.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  // Keeps the endless starfield still so pumpAndSettle can settle.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(service)],
      child: ShadApp(
        theme: AppTheme.dark,
        home: const LoginPage(),
        builder: (context, child) => AppToaster(child: child!),
      ),
    ),
  );
  return service;
}

void main() {
  testWidgets('toggle link shows and hides confirm field', (tester) async {
    await _pump(tester);
    expect(find.byKey(_confirm), findsNothing);
    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.tap(find.byKey(_toggle));
    await tester.pump();
    expect(find.byKey(_confirm), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Forgot password?'), findsNothing);

    await tester.tap(find.byKey(_toggle));
    await tester.pump();
    expect(find.byKey(_confirm), findsNothing);
  });

  testWidgets('toggling keeps typed email', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byKey(_email), 'a@b.com');

    await tester.tap(find.byKey(_toggle));
    await tester.pump();

    expect(find.text('a@b.com'), findsOneWidget);
  });

  testWidgets('empty submit shows errors and skips service', (tester) async {
    final service = await _pump(tester);

    await tester.tap(find.byKey(_submit));
    await tester.pump();

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(service.calls, isEmpty);
  });

  testWidgets('valid sign in calls service', (tester) async {
    final service = await _pump(tester);

    await tester.enterText(find.byKey(_email), 'a@b.com');
    await tester.enterText(find.byKey(_password), 'secret1');
    await tester.tap(find.byKey(_submit));
    await tester.pumpAndSettle();

    expect(service.calls, ['signIn:a@b.com:secret1']);
  });

  testWidgets('sign up rejects mismatched confirm', (tester) async {
    final service = await _pump(tester);
    await tester.tap(find.byKey(_toggle));
    await tester.pump();

    await tester.enterText(find.byKey(_email), 'a@b.com');
    await tester.enterText(find.byKey(_password), 'secret1');
    await tester.enterText(find.byKey(_confirm), 'secret2');
    await tester.tap(find.byKey(_submit));
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(service.calls, isEmpty);
  });

  testWidgets('valid sign up calls service', (tester) async {
    final service = await _pump(tester);
    await tester.tap(find.byKey(_toggle));
    await tester.pump();

    await tester.enterText(find.byKey(_email), 'a@b.com');
    await tester.enterText(find.byKey(_password), 'secret1');
    await tester.enterText(find.byKey(_confirm), 'secret1');
    await tester.tap(find.byKey(_submit));
    await tester.pumpAndSettle();

    expect(service.calls, ['signUp:a@b.com:secret1']);
  });

  testWidgets('service failure shows snackbar message', (tester) async {
    final service = await _pump(tester);
    service.failure = const AuthFailure('invalid-credential');

    await tester.enterText(find.byKey(_email), 'a@b.com');
    await tester.enterText(find.byKey(_password), 'wrong12');
    await tester.tap(find.byKey(_submit));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('hides brand instead of scaling it to zero when keyboard is up', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Mysic App'), findsOneWidget);

    // Leaves less room than the sheet needs, as on a phone with the keyboard.
    tester.view.viewInsets = const FakeViewPadding(bottom: 1200);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(find.text('Mysic App'), findsNothing);
    expect(find.byKey(_email), findsOneWidget);
  });

  testWidgets('forgot password sends reset email', (tester) async {
    final service = await _pump(tester);
    await tester.enterText(find.byKey(_email), 'a@b.com');

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset password'), findsOneWidget);

    await tester.tap(find.text('Send link'));
    await tester.pumpAndSettle();

    expect(service.calls, ['reset:a@b.com']);
    expect(find.text('Reset password'), findsNothing);
    expect(find.textContaining('reset link has been sent'), findsOneWidget);
  });

  testWidgetsOnScreens('sign in and sign up lay out without overflow', (
    tester,
    screen,
  ) async {
    await _pump(tester, screen: screen);
    await tester.pumpAndSettle();
    expect(find.byKey(_submit), findsOneWidget);

    // Small screens scroll the form, so bring the toggle into view first.
    await tester.ensureVisible(find.byKey(_toggle));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(find.byKey(_confirm), findsOneWidget);
  });
}
