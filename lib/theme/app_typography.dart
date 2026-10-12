import 'package:flutter/cupertino.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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

  /// Shad slots carry the Figma scale; styles Shad has no slot for go in
  /// [ShadTextTheme.custom] and are read via [AppShadText].
  static ShadTextTheme shadTextTheme(ShadColorScheme cs) => ShadTextTheme(
    family: AppFont.family,
    h2: _headlineMedium.copyWith(color: cs.foreground),
    h3: _headlineSmall.copyWith(color: cs.foreground),
    h4: _titleLarge.copyWith(color: cs.foreground),
    large: _titleMedium.copyWith(color: cs.foreground),
    p: _bodyLarge.copyWith(color: cs.foreground),
    small: _labelMedium.copyWith(color: cs.foreground),
    muted: _bodySmall.copyWith(color: cs.mutedForeground),
    custom: {
      _title: _titleSmall.copyWith(color: cs.foreground),
      _caption: _labelSmall.copyWith(color: cs.mutedForeground),
    },
  );

  /// Cupertino bars do not read ShadTextTheme, so the same scale is mirrored here.
  static CupertinoTextThemeData cupertinoTextTheme(ShadColorScheme cs) =>
      CupertinoTextThemeData(
        primaryColor: cs.primary,
        textStyle: _bodyMedium.copyWith(color: cs.foreground),
        navTitleTextStyle: _titleMedium.copyWith(color: cs.foreground),
        navLargeTitleTextStyle: _headlineMedium.copyWith(color: cs.foreground),
        tabLabelTextStyle: _labelSmall.copyWith(color: cs.mutedForeground),
        actionTextStyle: _labelLarge.copyWith(color: cs.primary),
      );

  static const String _title = 'title';
  static const String _caption = 'caption';
}

extension AppShadText on ShadTextTheme {
  TextStyle get title => custom[AppTypography._title]!;
  TextStyle get caption => custom[AppTypography._caption]!;
}
