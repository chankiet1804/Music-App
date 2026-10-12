import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/app.dart';
import 'package:music_app/firebase_options.dart';

Future<void> main() async {
  // Must run before any binding is created, since it installs its own binding.
  DevicePreview.enable(enabled: kDebugMode);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MysicApp()));
}
