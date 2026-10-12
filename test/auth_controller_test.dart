import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/core/auth/auth_controller.dart';
import 'package:music_app/core/auth/auth_providers.dart';
import 'package:music_app/data/model/auth_failure.dart';

import 'fakes/fake_auth_service.dart';

ProviderContainer _container(FakeAuthService service) {
  final container = ProviderContainer(
    overrides: [authServiceProvider.overrideWithValue(service)],
  );
  addTearDown(container.dispose);
  addTearDown(service.dispose);
  return container;
}

void main() {
  test('signIn calls service and ends in data state', () async {
    final service = FakeAuthService();
    final container = _container(service);
    final controller = container.read(authControllerProvider.notifier);

    await controller.signIn('a@b.com', 'secret1');

    expect(service.calls, ['signIn:a@b.com:secret1']);
    expect(container.read(authControllerProvider), isA<AsyncData<void>>());
  });

  test('state is loading while the call is in flight', () async {
    final service = FakeAuthService()..gate = Completer();
    final container = _container(service);
    final controller = container.read(authControllerProvider.notifier);

    final pending = controller.signIn('a@b.com', 'secret1');
    expect(container.read(authControllerProvider).isLoading, isTrue);

    service.gate!.complete();
    await pending;
    expect(container.read(authControllerProvider).isLoading, isFalse);
  });

  test('service failure becomes AsyncError with mapped message', () async {
    final service = FakeAuthService()
      ..failure = const AuthFailure('invalid-credential');
    final container = _container(service);

    await container
        .read(authControllerProvider.notifier)
        .signIn('a@b.com', 'wrong1');

    final state = container.read(authControllerProvider);
    expect(state.hasError, isTrue);
    expect(
      (state.error! as AuthFailure).message,
      'Incorrect email or password.',
    );
  });

  test('signUp, resetPassword and signOut delegate to service', () async {
    final service = FakeAuthService();
    final container = _container(service);
    final controller = container.read(authControllerProvider.notifier);

    await controller.signUp('a@b.com', 'secret1');
    await controller.resetPassword('a@b.com');
    await controller.signOut();

    expect(service.calls, [
      'signUp:a@b.com:secret1',
      'reset:a@b.com',
      'signOut',
    ]);
  });

  test('authStateProvider follows sign-in and sign-out', () async {
    final service = FakeAuthService();
    final container = _container(service);
    final sub = container.listen(authStateProvider, (_, _) {});
    addTearDown(sub.close);

    expect(await container.read(authStateProvider.future), isNull);

    await container
        .read(authControllerProvider.notifier)
        .signIn('a@b.com', 'x');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authStateProvider).value?.email, 'a@b.com');

    await container.read(authControllerProvider.notifier).signOut();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authStateProvider).value, isNull);
  });
}
