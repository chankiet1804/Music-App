import 'package:flutter/material.dart';
import 'package:music_app/router.dart';
import 'package:music_app/theme/theme.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class MysicApp extends StatelessWidget {
  const MysicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.router(
      routerConfig: router,
      title: 'Mysic App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      materialThemeBuilder: AppTheme.materialTheme,
    );
  }
}
