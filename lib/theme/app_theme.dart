import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:music_app/theme/app_colors.dart';
import 'package:music_app/theme/app_dimens.dart';
import 'package:music_app/theme/app_typography.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

abstract final class AppTheme {
  static const ShadColorScheme _colorScheme = ShadColorScheme(
    background: AppColors.background,
    foreground: AppColors.textPrimary,
    card: AppColors.surface,
    cardForeground: AppColors.textPrimary,
    popover: AppColors.surfaceElevated,
    popoverForeground: AppColors.textPrimary,
    primary: AppColors.primary,
    primaryForeground: AppColors.onPrimary,
    secondary: AppColors.surfaceElevated,
    secondaryForeground: AppColors.textPrimary,
    muted: AppColors.surfaceElevated,
    mutedForeground: AppColors.textMuted,
    accent: AppColors.surfaceElevated,
    accentForeground: AppColors.textPrimary,
    destructive: AppColors.destructive,
    destructiveForeground: AppColors.textPrimary,
    border: AppColors.divider,
    input: AppColors.divider,
    ring: AppColors.primary,
    selection: AppColors.selection,
    custom: {
      AppShadColors._textSecondary: AppColors.textSecondary,
      AppShadColors._barBorder: AppColors.barBorder,
    },
  );

  static final ShadThemeData dark = ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: _colorScheme,
    textTheme: AppTypography.shadTextTheme(_colorScheme),
    radius: BorderRadius.circular(AppRadius.xs),
  );

  /// Material and Cupertino widgets still in use (Scaffold, progress
  /// indicators, the Cupertino nav bar) read this, derived from [dark].
  static ThemeData materialTheme(BuildContext context, ThemeData theme) {
    final cs = ShadTheme.of(context).colorScheme;

    return theme.copyWith(
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.border,
      ),
      iconTheme: IconThemeData(color: cs.foreground, size: AppIconSize.sm),
      // Cupertino widgets ignore ThemeData; this override is what colours
      // CupertinoPageScaffold and CupertinoNavigationBar.
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: cs.primary,
        primaryContrastingColor: cs.primaryForeground,
        barBackgroundColor: cs.card,
        scaffoldBackgroundColor: cs.background,
        textTheme: AppTypography.cupertinoTextTheme(cs),
      ),
    );
  }
}

/// Palette entries Shad has no slot for, stored in [ShadColorScheme.custom].
extension AppShadColors on ShadColorScheme {
  static const String _textSecondary = 'textSecondary';
  static const String _barBorder = 'barBorder';

  Color get textSecondary => custom[_textSecondary]!;
  Color get barBorder => custom[_barBorder]!;
}
