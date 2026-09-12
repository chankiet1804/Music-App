import 'package:flutter/painting.dart';

/// Raw Figma palette. The only place hex literals live.
/// Never reference these from UI - go through ColorScheme or AppTokens.
abstract final class AppColors {
  static const Color background = Color(0xFF0A071E);
  static const Color surface = Color(0xFF0A091E);

  /// Not from Figma: its surface (#0A091E) is indistinguishable from the
  /// canvas, so an actual elevated step is needed for cards and pills.
  static const Color surfaceElevated = Color(0xFF14122E);

  static const Color primary = Color(0xFF6156E2);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFFF2F2F2);
  static const Color textSecondary = Color(0xFFDEDEDE);
  static const Color textMuted = Color(0xFF8E8E8E);

  // Derived. Alpha is pre-computed so these stay const.
  static const Color divider = Color(0x338E8E8E); // textMuted @ 20%
  static const Color barBorder = Color(0x1F8E8E8E); // textMuted @ 12%
  static const Color navShadow = Color(0x1AA8BACF); // rgba(168,186,207,0.1)
}
