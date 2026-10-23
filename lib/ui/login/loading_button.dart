import 'package:flutter/material.dart';
import 'package:music_app/theme/theme.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Primary pill button with the brand gradient and a shine that sweeps
/// across every few seconds. For [isLoading] the label slides up and out
/// while a spinner and [loadingLabel] slide in. Ported from Native Bloom's
/// "Loading button".
class LoadingButton extends StatefulWidget {
  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    required this.loadingLabel,
    this.width,
  });

  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;

  /// What is happening while loading, e.g. "Signing in...".
  final Widget loadingLabel;
  final double? width;

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton>
    with TickerProviderStateMixin {
  static const _curve = Cubic(0.4, 0, 0.2, 1);
  static const _pill = BorderRadius.all(Radius.circular(AppRadius.full));
  static const _slide = 20.0;
  static const _outInterval = Interval(0, 0.5);
  static const _inInterval = Interval(0.5, 1);

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: widget.isLoading ? 1 : 0,
  );
  late final _progress = CurvedAnimation(parent: _controller, curve: _curve);

  /// Sweeps during the first part of each cycle and rests for the remainder.
  late final _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  static const _shineInterval = Interval(0, 0.35, curve: Curves.easeInOut);
  bool _reduceMotion = false;
  bool _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncShine();
  }

  // Idle only: a shine over the spinner would read as progress.
  void _syncShine() {
    final run = !widget.isLoading && !_reduceMotion;
    if (run && !_shine.isAnimating) {
      _shine.repeat();
    } else if (!run && _shine.isAnimating) {
      _shine
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didUpdateWidget(LoadingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading == oldWidget.isLoading) return;
    _syncShine();
    if (widget.isLoading) {
      _pressed = false;
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    _shine.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    final canPress = !widget.isLoading && widget.onPressed != null;
    final value = pressed && canPress;
    if (value != _pressed) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;

    return AnimatedScale(
      scale: _pressed ? 0.95 : 1,
      duration: Duration(milliseconds: _pressed ? 100 : 200),
      child: AnimatedBuilder(
        animation: Listenable.merge([_progress, _shine]),
        builder: (context, _) {
          final t = _progress.value;
          // Dims towards the background while loading.
          Color dim(Color c) => Color.lerp(c, cs.background, 0.4 * t)!;
          final shine = _shineInterval.transform(_shine.value);
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) => _shineShader(rect, shine),
            child: _button(cs, t, dim),
          );
        },
      ),
    );
  }

  /// Diagonal white band, off the left edge at 0 and off the right at 1.
  Shader _shineShader(Rect rect, double shine) {
    return LinearGradient(
      begin: const Alignment(-1, -0.4),
      end: const Alignment(1, 0.4),
      colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: shine > 0 && shine < 1 ? 0.35 : 0),
        Colors.transparent,
      ],
      stops: const [0.4, 0.5, 0.6],
      transform: _SlideX(-1 + 2 * shine),
    ).createShader(rect);
  }

  Widget _button(ShadColorScheme cs, double t, Color Function(Color) dim) {
    return ShadButton(
      width: widget.width,
      height: 50,
      gradient: LinearGradient(colors: [dim(cs.primary), dim(cs.brandPink)]),
      decoration: const ShadDecoration(
        border: ShadBorder(radius: _pill),
        secondaryFocusedBorder: ShadBorder(
          radius: BorderRadius.all(Radius.circular(AppRadius.full + 2)),
        ),
      ),
      onPressed: widget.isLoading ? null : widget.onPressed,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      // No clip: each layer is faded out before it slides past the
      // button's padding, so nothing visible leaves the button.
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 1 - _outInterval.transform(t),
            child: Transform.translate(
              offset: Offset(0, -_slide * t),
              child: widget.child,
            ),
          ),
          // Always laid out so the button fits the wider of the two
          // layers; the spinner itself only exists while visible
          // because it never settles.
          ExcludeSemantics(
            excluding: t == 0,
            child: Opacity(
              opacity: _inInterval.transform(t),
              child: Transform.translate(
                offset: Offset(0, _slide * (1 - t)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 16,
                      child: t > 0
                          ? CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primaryForeground,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    // Ellipsize instead of overflowing narrow buttons.
                    Flexible(
                      child: DefaultTextStyle.merge(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: widget.loadingLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shifts a gradient horizontally by [fraction] of the box width.
class _SlideX extends GradientTransform {
  const _SlideX(this.fraction);

  final double fraction;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * fraction, 0, 0);
}
