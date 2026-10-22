import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:music_app/shared/widgets/toast/app_toast.dart';
import 'package:music_app/shared/widgets/toast/toast_body.dart';
import 'package:music_app/shared/widgets/toast/toast_spec.dart';

/// Resting pose of a toast for its slot in the stack.
@immutable
class ToastTarget {
  const ToastTarget({
    required this.y,
    required this.scale,
    required this.opacity,
    this.clipHeight,
  });

  /// Distance from the viewport edge, towards the screen centre.
  final double y;
  final double scale;
  final double opacity;

  /// Collapsed back toasts are clipped to the front toast's height.
  final double? clipHeight;
}

/// One toast in the [AppToaster] stack. Must be a direct child of its [Stack].
///
/// Owns its motion (springs towards [target]), swipe-to-dismiss and the
/// auto-dismiss timer. Removal is two-step: [onDismiss] asks the toaster to
/// drop it from the layout, [onRemoved] fires once the exit animation ends.
class ToastItem extends StatefulWidget {
  const ToastItem({
    super.key,
    required this.data,
    required this.target,
    required this.position,
    required this.left,
    required this.width,
    required this.edgeInset,
    required this.paused,
    required this.dismissing,
    required this.onHeight,
    required this.onTap,
    required this.onDismiss,
    required this.onRemoved,
  });

  final AppToastData data;
  final ToastTarget target;
  final AppToastPosition position;
  final double left;
  final double width;
  final double edgeInset;
  final bool paused;
  final bool dismissing;
  final ValueChanged<double> onHeight;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback onRemoved;

  @override
  State<ToastItem> createState() => _ToastItemState();
}

class _ToastItemState extends State<ToastItem> with TickerProviderStateMixin {
  late final _y = _Spring(this, widget.target.y);
  late final _scale = _Spring(this, widget.target.scale);
  late final _clip = _Spring(this, 0);
  late final _opacity = AnimationController(
    vsync: this,
    duration: ToastSpec.fade,
    value: widget.target.opacity,
  );
  late final _presence = AnimationController.unbounded(vsync: this);
  late final _dragX = AnimationController.unbounded(vsync: this);
  late final _dragY = AnimationController.unbounded(vsync: this);

  double? _height;
  bool _exiting = false;

  bool _dragging = false;
  Offset _rawDrag = Offset.zero;
  Axis? _axis;

  Timer? _timer;
  final _watch = Stopwatch();
  late Duration _remaining = _lifetime;

  double get _dir => widget.position == AppToastPosition.top ? 1 : -1;

  Duration get _lifetime => widget.data.duration ?? ToastSpec.lifetime;

  bool get _timerShouldRun =>
      !widget.paused &&
      !_dragging &&
      !_exiting &&
      widget.data.type != AppToastType.loading;

  @override
  void initState() {
    super.initState();
    _presence
        .animateWith(SpringSimulation(ToastSpec.glide, 0, 1, 0))
        .whenComplete(() => _presence.value = 1);
    _syncTimer();
  }

  @override
  void didUpdateWidget(ToastItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _cancelTimer();
      _remaining = _lifetime;
    }
    if (widget.dismissing) _exit();
    if (!_exiting) {
      _y.animateTo(widget.target.y, ToastSpec.glide);
      _scale.animateTo(widget.target.scale, ToastSpec.glide);
      _opacity.animateTo(widget.target.opacity);
      _syncClip();
    }
    _syncTimer();
  }

  @override
  void dispose() {
    _cancelTimer();
    for (final c in [
      _y.controller,
      _scale.controller,
      _clip.controller,
      _opacity,
      _presence,
      _dragX,
      _dragY,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncTimer() {
    if (_timerShouldRun) {
      if (_timer != null) return;
      _watch
        ..reset()
        ..start();
      _timer = Timer(_remaining, () => widget.onDismiss());
    } else if (_timer != null) {
      _cancelTimer();
      _watch.stop();
      _remaining -= _watch.elapsed;
      if (_remaining.isNegative) _remaining = Duration.zero;
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _syncClip({bool jump = false}) {
    final height = _height;
    if (height == null) return;
    final target = widget.target.clipHeight ?? height;
    if (jump) {
      _clip.jumpTo(target);
    } else {
      _clip.animateTo(target, ToastSpec.glide);
    }
  }

  void _onSize(Size size) {
    if (!mounted || size.height == _height) return;
    final first = _height == null;
    setState(() => _height = size.height);
    widget.onHeight(size.height);
    _syncClip(jump: first);
  }

  void _exit() {
    if (_exiting) return;
    _exiting = true;
    _syncTimer();
    _presence
        .animateTo(0, duration: ToastSpec.exit, curve: Curves.easeIn)
        .whenComplete(_onExited);
  }

  void _onExited() {
    if (mounted) widget.onRemoved();
  }

  void _onPanStart(DragStartDetails details) {
    if (_exiting) return;
    _dragging = true;
    _rawDrag = Offset.zero;
    _axis = null;
    _dragX.stop();
    _dragY.stop();
    _syncTimer();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    _rawDrag += details.delta;
    _axis ??= _lockAxis(_rawDrag);
    switch (_axis) {
      case Axis.horizontal:
        _dragX.value = _rawDrag.dx;
      case Axis.vertical:
        // Only the edge-ward direction tracks 1:1; the other way resists.
        final towardEdge = _dir * _rawDrag.dy < 0;
        _dragY.value = towardEdge
            ? _rawDrag.dy
            : _rawDrag.dy * ToastSpec.swipeAgainstFactor;
      case null:
        break;
    }
  }

  Axis? _lockAxis(Offset raw) {
    if (raw.dx.abs() < ToastSpec.swipeAxisLock &&
        raw.dy.abs() < ToastSpec.swipeAxisLock) {
      return null;
    }
    return raw.dx.abs() > raw.dy.abs() ? Axis.horizontal : Axis.vertical;
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    final velocity = details.velocity.pixelsPerSecond;
    final screen = MediaQuery.sizeOf(context);

    switch (_axis) {
      case Axis.horizontal:
        final dx = _dragX.value;
        if (dx.abs() >= ToastSpec.swipeThreshold ||
            velocity.dx.abs() >= ToastSpec.swipeVelocity) {
          final sign = dx != 0 ? dx.sign : velocity.dx.sign;
          return _swipeOut(_dragX, sign * screen.width);
        }
      case Axis.vertical:
        final travel = -_dir * _dragY.value;
        final speed = -_dir * velocity.dy;
        if (travel > 0 &&
            (travel >= ToastSpec.swipeThreshold ||
                speed >= ToastSpec.swipeVelocity)) {
          return _swipeOut(
            _dragY,
            -_dir * screen.height * ToastSpec.swipeExitHeightFactor,
          );
        }
      case null:
        break;
    }
    _snapBack();
    _syncTimer();
  }

  void _onPanCancel() {
    if (!_dragging) return;
    _dragging = false;
    _snapBack();
    _syncTimer();
  }

  void _snapBack() {
    for (final c in [_dragX, _dragY]) {
      if (c.value == 0) continue;
      c.animateWith(SpringSimulation(ToastSpec.snappy, c.value, 0, c.velocity));
    }
  }

  void _swipeOut(AnimationController drag, double to) {
    HapticFeedback.lightImpact();
    _exiting = true;
    _syncTimer();
    drag.animateTo(to, duration: ToastSpec.exit, curve: Curves.easeOut);
    _presence
        .animateTo(0, duration: ToastSpec.exit)
        .whenComplete(_onExited);
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final top = widget.position == AppToastPosition.top;

    return Positioned(
      left: widget.left,
      width: widget.width,
      top: top ? widget.edgeInset : null,
      bottom: top ? null : widget.edgeInset,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _y.controller,
          _scale.controller,
          _clip.controller,
          _opacity,
          _presence,
          _dragX,
          _dragY,
        ]),
        builder: (context, child) {
          final presence = _presence.value;
          final enterDistance =
              (_height ?? ToastSpec.fallbackHeight) + ToastSpec.enterExtra;
          final dy =
              _dir * _y.value -
              _dir * enterDistance * (1 - presence) +
              _dragY.value;
          final scale =
              _scale.value *
              (ToastSpec.enterScale + (1 - ToastSpec.enterScale) * presence);
          final travel = _dragX.value.abs() + _dragY.value.abs();
          final swipeFade =
              1 - math.min(1.0, travel / ToastSpec.swipeFadeDistance);
          final opacity = (_opacity.value * presence * swipeFade).clamp(
            0.0,
            1.0,
          );
          final height = _height;
          final heightFactor = height == null || height == 0
              ? null
              : _clip.value / height;

          return Transform.translate(
            offset: Offset(_dragX.value, dy),
            child: Transform.scale(
              scale: scale,
              // Keeps the peeking edge of back toasts at a constant offset.
              alignment: top ? Alignment.bottomCenter : Alignment.topCenter,
              child: Opacity(
                opacity: opacity,
                child: ClipRect(
                  // Clipping only when needed so the card shadow survives.
                  clipBehavior: (heightFactor ?? 1) < 0.999
                      ? Clip.hardEdge
                      : Clip.none,
                  child: Align(
                    alignment: top
                        ? Alignment.topCenter
                        : Alignment.bottomCenter,
                    heightFactor: heightFactor,
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
        child: IgnorePointer(
          ignoring: widget.dismissing || widget.target.opacity == 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTap: widget.onTap,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onPanCancel: _onPanCancel,
            child: Material(
              type: MaterialType.transparency,
              child: _MeasureSize(
                onChange: _onSize,
                child: ToastBody(data: widget.data),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Unbounded controller that springs to a target, keeping its velocity when
/// the target changes mid-flight.
class _Spring {
  _Spring(TickerProvider vsync, double value)
    : _target = value,
      controller = AnimationController.unbounded(vsync: vsync, value: value);

  final AnimationController controller;
  double _target;

  double get value => controller.value;

  void animateTo(double target, SpringDescription spring) {
    if (target == _target) return;
    _target = target;
    controller
        .animateWith(
          SpringSimulation(spring, controller.value, target, controller.velocity),
        )
        // The simulation stops within tolerance; land exactly on target.
        .whenComplete(() => controller.value = target);
  }

  void jumpTo(double value) {
    _target = value;
    controller.value = value;
  }
}

/// Reports its child's laid-out size after the frame.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMeasureSize renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reported) return;
    _reported = size;
    final measured = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(measured));
  }
}
