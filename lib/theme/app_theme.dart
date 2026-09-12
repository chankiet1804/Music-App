import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:music_app/theme/app_colors.dart';
import 'package:music_app/theme/app_dimens.dart';
import 'package:music_app/theme/app_tokens.dart';
import 'package:music_app/theme/app_typography.dart';

abstract final class AppTheme {
  static final ThemeData dark = _build();

  static ThemeData _build() {
    const cs = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primary,
      onSecondary: AppColors.onPrimary,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceElevated,
      onSurfaceVariant: AppColors.textSecondary,
      outlineVariant: AppColors.divider,
    );

    final textTheme = AppTypography.textTheme(cs);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      fontFamily: AppFont.family,
      // Scaffold would otherwise use cs.surfaceContainer and sit 2pts off the
      // canvas colour, which is visible where Scaffold nests in Cupertino.
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppIconSize.sm,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: AppBorders.hairline,
        space: AppBorders.hairline,
        indent: AppSpacing.xl,
        endIndent: AppSpacing.xl,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.lg,
        ),
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textMuted,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.divider,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
      ),
      extensions: const <ThemeExtension<dynamic>>[AppTokens.dark],
      // Cupertino widgets ignore ThemeData; this override is what colours
      // CupertinoPageScaffold, CupertinoNavigationBar and CupertinoTabBar.
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        primaryContrastingColor: AppColors.onPrimary,
        barBackgroundColor: AppColors.surface,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: AppTypography.cupertinoTextTheme(cs),
      ),
    );
  }
}
