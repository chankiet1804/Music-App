import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/app.dart';

void main() {
  DevicePreview.enable(enabled: kDebugMode);
  runApp(const ProviderScope(child: MysicApp()));
}
