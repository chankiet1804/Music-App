import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Runs before every test file in this directory. Without real fonts every
// glyph renders as a full-width square, so text measures far wider than on
// a device and overflow checks give false positives.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFont('Nunito', [
    'assets/fonts/Nunito-Regular.ttf',
    'assets/fonts/Nunito-SemiBold.ttf',
  ]);
  await _loadFont('packages/shadcn_ui/Geist', [
    'packages/shadcn_ui/fonts/Geist[wght].ttf',
  ]);
  await testMain();
}

Future<void> _loadFont(String family, List<String> assets) {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  return loader.load();
}
