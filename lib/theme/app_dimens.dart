/// Dimension scales. Theme-invariant, so they are plain constants rather than
/// ThemeExtension fields - this keeps every call site const.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 64;

  /// Screen horizontal padding. Figma says 21, snapped to the 8pt grid.
  static const double screenH = 24;
}

abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 30;
  static const double xxl = 36;
  static const double full = 40;
}

abstract final class AppIconSize {
  static const double sm = 24;
  static const double md = 36;
  static const double lg = 48;
}

abstract final class AppNavBar {
  static const double height = 85;

  /// Side gutter so the bar floats off the screen edges, per Figma.
  static const double inset = 20;
}

abstract final class AppBorders {
  static const double hairline = 1.0;
  static const double progressBar = 3.0;
}
