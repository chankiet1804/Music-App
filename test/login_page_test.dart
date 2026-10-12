import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/core/auth/auth_providers.dart';
import 'package:music_app/data/model/auth_failure.dart';
import 'package:music_app/ui/login/login.dart';

import 'fakes/fake_auth_service.dart';

const _email = Key('login.email');
const _password = Key('login.password');
const _confirm = Key('login.confirm');
const _submit = Key('login.submit');
const _toggle = Key('login.toggle');

Future<FakeAuthService> _pump(WidgetTester tester) async {
  final service = FakeAuthService();
  addTearDown(service.dispose);
  // Tall surface so the whole scrollable form is laid out.
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(service)],
      child: const MaterialApp(home: LoginPage()),
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
}
