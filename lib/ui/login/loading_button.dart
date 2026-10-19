import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Primary button whose label slides up and out while a spinner and
/// [loadingLabel] slide in for [isLoading]. Ported from Native Bloom's
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
    with SingleTickerProviderStateMixin {
  static const _curve = Cubic(0.4, 0, 0.2, 1);
  static const _slide = 20.0;
  static const _outInterval = Interval(0, 0.5);
  static const _inInterval = Interval(0.5, 1);

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: widget.isLoading ? 1 : 0,
  );
  late final _progress = CurvedAnimation(parent: _controller, curve: _curve);
  bool _pressed = false;

  @override
  void didUpdateWidget(LoadingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading == oldWidget.isLoading) return;
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
    final loadingColor = Color.lerp(cs.primary, cs.background, 0.4)!;

    return AnimatedScale(
      scale: _pressed ? 0.95 : 1,
      duration: Duration(milliseconds: _pressed ? 100 : 200),
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          final t = _progress.value;
          final background = Color.lerp(cs.primary, loadingColor, t)!;
          return ShadButton(
            width: widget.width,
            backgroundColor: background,
            hoverBackgroundColor: t > 0 ? background : null,
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
        },
      ),
    );
  }
}
