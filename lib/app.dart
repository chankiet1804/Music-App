import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/router.dart';
import 'package:music_app/shared/widgets/toast/app_toaster.dart';
import 'package:music_app/theme/theme.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class MysicApp extends ConsumerWidget {
  const MysicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShadApp.router(
      routerConfig: ref.watch(routerProvider),
      title: 'Mysic App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      materialThemeBuilder: AppTheme.materialTheme,
      builder: (context, child) => AppToaster(child: child!),
    );
  }
}
