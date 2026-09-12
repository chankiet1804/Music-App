import 'package:flutter/material.dart';
import 'package:music_app/theme/app_colors.dart';

/// Design tokens Material has no slot for. Colors only - dimension scales are
/// theme-invariant and live in app_dimens.dart as plain constants.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.surfaceElevated,
    required this.textMuted,
    required this.navInactive,
    required this.barBorder,
    required this.navBarShadow,
  });

  final Color surfaceElevated;
  final Color textMuted;
  final Color navInactive;
  final Color barBorder;
  final BoxShadow navBarShadow;

  static const AppTokens dark = AppTokens(
    surfaceElevated: AppColors.surfaceElevated,
    textMuted: AppColors.textMuted,
    navInactive: AppColors.textMuted,
    barBorder: AppColors.barBorder,
    navBarShadow: BoxShadow(
      color: AppColors.navShadow,
      offset: Offset(0, -5),
      blurRadius: 20,
    ),
  );

  /// Falls back to [dark] so widget tests pumping a bare MaterialApp still work.
  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>() ?? dark;

  @override
  AppTokens copyWith({
    Color? surfaceElevated,
    Color? textMuted,
    Color? navInactive,
    Color? barBorder,
    BoxShadow? navBarShadow,
  }) {
    return AppTokens(
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textMuted: textMuted ?? this.textMuted,
      navInactive: navInactive ?? this.navInactive,
      barBorder: barBorder ?? this.barBorder,
      navBarShadow: navBarShadow ?? this.navBarShadow,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      barBorder: Color.lerp(barBorder, other.barBorder, t)!,
      navBarShadow: BoxShadow.lerp(navBarShadow, other.navBarShadow, t)!,
    );
  }
}
