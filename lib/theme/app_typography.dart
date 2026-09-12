import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:music_app/theme/app_colors.dart';

abstract final class AppFont {
  static const String family = 'Nunito';
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight semiBold = FontWeight.w600;
}

/// Type scale from Figma. Line heights there are broken (20px hardcoded on
/// 22/26px text), so sane 1.2-1.4 ratios are used instead.
abstract final class AppTypography {
  static const TextStyle _headlineMedium = TextStyle(
    fontFamily: AppFont.family,
    fontSize: 26,
    fontWeight: AppFont.semiBold,
    letterSpacing: -0.24,
    height: 1.25,
  );

  static const TextStyle _headlineSmall = TextStyle(
    fontFamily: AppFont.family,
    fontSize: 24,
    fontWeight: AppFont.semiBold,
    letterSpacing: -0.24,
    height: 1.25,
  );

  static const TextStyle _titleLarge = TextStyle(
    fontFamily: AppFont.family,
    fontSize: 22,
    fontWeight: AppFont.semiBold,
    letterSpacing: -0.24,
    height: 1.27,
  );

  static const TextStyle _titleMedium = TextStyle(
    fontFamily: AppFont.family,
    fontSize: 18,
    fontWeight: AppFont.semiBold,
    letterSpacing: -0.24,
    height: 1.33,
  );

  static const TextStyle _titleSmall = TextStyle(
    fontFamily: AppFont.family,
    fontSize: 17,
    fontWeight: AppFont.semiBold,
    letterSpacing: -0.41,
    height: 1.30,
  );

  static const TextStyle _bodyLarge = TextStyle(
    fontFamily: AppFont.family,
    fontSize: 16,
    fontWeight: AppFont.regular,
    letterSpacing: -0.24,
    height: 1.375,
  );

  static const TextStyle _bodyMedium = TextStyle(
    fontFamily: AppFont.family,
    fontSize: 15,
    fontWeight: AppFont.regular,
    letterSpacing: -0.24,
    height: 1.35,
  );

  static const TextStyle _bodySmall = TextStyle(
    fontFamily: AppFont.family,
    fontSize: 14,
    fontWeight: AppFont.regular,
    letterSpacing: -0.08,
    height: 1.40,
  );

  static const TextStyle _labelLarge = TextStyle(
    fontFamily: AppFont.family,
    fontSize: 16,
    fontWeight: AppFont.semiBold,
    letterSpacing: -0.24,
    height: 1.25,
  );

  static const TextStyle _labelMedium = TextStyle(
    fontFamily: AppFont.family,
    fontSize: 14,
    fontWeight: AppFont.semiBold,
    letterSpacing: -0.08,
    height: 1.40,
  );

  static const TextStyle _labelSmall = TextStyle(
    fontFamily: AppFont.family,
    fontSize: 13,
    fontWeight: AppFont.regular,
    letterSpacing: -0.08,
    height: 1.40,
  );

  static TextTheme textTheme(ColorScheme cs) => TextTheme(
    headlineMedium: _headlineMedium.copyWith(color: cs.onSurface),
    headlineSmall: _headlineSmall.copyWith(color: cs.onSurface),
    titleLarge: _titleLarge.copyWith(color: cs.onSurface),
    titleMedium: _titleMedium.copyWith(color: cs.onSurface),
    titleSmall: _titleSmall.copyWith(color: cs.onSurface),
    bodyLarge: _bodyLarge.copyWith(color: cs.onSurface),
    bodyMedium: _bodyMedium.copyWith(color: cs.onSurface),
    bodySmall: _bodySmall.copyWith(color: cs.onSurfaceVariant),
    labelLarge: _labelLarge.copyWith(color: cs.onSurface),
    labelMedium: _labelMedium.copyWith(color: cs.onSurfaceVariant),
    labelSmall: _labelSmall.copyWith(color: AppColors.textMuted),
  );

  /// Cupertino bars do not read TextTheme, so the same scale is mirrored here.
  static CupertinoTextThemeData cupertinoTextTheme(ColorScheme cs) =>
      CupertinoTextThemeData(
        primaryColor: cs.primary,
        textStyle: _bodyMedium.copyWith(color: cs.onSurface),
        navTitleTextStyle: _titleMedium.copyWith(color: cs.onSurface),
        navLargeTitleTextStyle: _headlineMedium.copyWith(color: cs.onSurface),
        tabLabelTextStyle: _labelSmall,
        actionTextStyle: _labelLarge.copyWith(color: cs.primary),
      );
}
