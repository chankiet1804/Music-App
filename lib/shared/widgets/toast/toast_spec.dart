import 'package:flutter/physics.dart';

/// Toast tuning, ported from the Reacticx toast block.
abstract final class ToastSpec {
  static const Duration lifetime = Duration(milliseconds: 4000);
  static const int visible = 3;

  // Stack layout.
  static const double gap = 14;
  static const double collapseOffset = 16;
  static const double collapseScaleStep = 0.05;
  static const double minScale = 0.8;
  static const double viewportOffset = 16;
  static const double maxWidth = 420;
  static const double fallbackHeight = 56;

  // Body.
  static const double iconSize = 20;
  static const double iconGap = 12;

  // Enter / exit.
  static const double enterExtra = 16;
  static const double enterScale = 0.94;
  static const Duration exit = Duration(milliseconds: 200);
  static const Duration fade = Duration(milliseconds: 300);

  // Swipe.
  static const double swipeAxisLock = 4;
  static const double swipeThreshold = 45;
  static const double swipeVelocity = 300;
  static const double swipeAgainstFactor = 0.2;
  static const double swipeFadeDistance = 200;
  static const double swipeExitHeightFactor = 0.6;

  static const SpringDescription glide = SpringDescription(
    mass: 1,
    stiffness: 170,
    damping: 32,
  );
  static const SpringDescription snappy = SpringDescription(
    mass: 0.8,
    stiffness: 280,
    damping: 24,
  );
}
