import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Endless field of stars flying towards the viewer, ported from Native
/// Bloom's "Starfield atlas animation". [boosted] ramps the flight speed up.
/// Stays still when the platform asks to reduce motion.
class StarfieldBackground extends StatefulWidget {
  const StarfieldBackground({
    super.key,
    required this.color,
    this.boosted = false,
  });

  final Color color;
  final bool boosted;

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with SingleTickerProviderStateMixin {
  static const _count = 800;
  static const _starSize = 8.0;

  // Depth units per second. The original moves 1 (default) to 20 (slider
  // max) units per frame at 60 fps; time-based so 120 Hz screens match.
  static const _normalSpeed = 60.0;
  static const _boostedSpeed = 600.0;

  // Time to go fully between normal and boosted speed, eased in and out so
  // the acceleration builds up gradually.
  static const _rampSeconds = 1.5;

  final _random = math.Random();
  final _xs = Float32List(_count);
  final _ys = Float32List(_count);
  final _zs = Float32List(_count);
  final _transforms = Float32List(_count * 4);
  final _rects = Float32List(_count * 4);
  final _repaint = ValueNotifier<int>(0);
  late final Ticker _ticker = createTicker(_tick);

  Duration _lastElapsed = Duration.zero;
  // 0 = normal speed, 1 = boosted.
  double _boost = 0;
  Size _size = Size.zero;
  ui.Image? _sprite;
  double _spriteDpr = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (dpr != _spriteDpr) _buildSprite(dpr);

    final animate = !MediaQuery.disableAnimationsOf(context);
    if (animate && !_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (!animate && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void didUpdateWidget(StarfieldBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != oldWidget.color) _buildSprite(_spriteDpr);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    _sprite?.dispose();
    super.dispose();
  }

  /// Rasterizes one round star at device resolution; every star reuses it.
  void _buildSprite(double dpr) {
    final px = (_starSize * dpr).ceil();
    final recorder = ui.PictureRecorder();
    Canvas(
      recorder,
    ).drawCircle(Offset(px / 2, px / 2), px / 2, Paint()..color = widget.color);
    final picture = recorder.endRecording();
    _sprite?.dispose();
    _sprite = picture.toImageSync(px, px);
    picture.dispose();
    _spriteDpr = dpr;

    for (var i = 0; i < _count; i++) {
      _rects.setAll(i * 4, [0, 0, px.toDouble(), px.toDouble()]);
    }
    _writeTransforms();
  }

  void _seed() {
    final w = _size.width;
    final h = _size.height;
    for (var i = 0; i < _count; i++) {
      _xs[i] = _randomIn(-w / 2, w / 2);
      _ys[i] = _randomIn(-h / 2, h / 2);
      _zs[i] = _randomIn(1, w);
    }
    _writeTransforms();
  }

  double _randomIn(double min, double max) =>
      _random.nextDouble() * (max - min) + min;

  void _tick(Duration elapsed) {
    final dt = math.min(
      (elapsed - _lastElapsed).inMicroseconds / Duration.microsecondsPerSecond,
      0.05,
    );
    _lastElapsed = elapsed;

    final direction = widget.boosted ? 1 : -1;
    _boost = (_boost + direction * dt / _rampSeconds).clamp(0.0, 1.0);
    final speed = ui.lerpDouble(
      _normalSpeed,
      _boostedSpeed,
      Curves.easeInOut.transform(_boost),
    )!;

    _advance(speed * dt);
    _repaint.value++;
  }

  /// Moves every star closer by [step]; stars that pass the viewer or leave
  /// the screen respawn at the back.
  void _advance(double step) {
    final w = _size.width;
    final h = _size.height;
    if (w <= 0 || h <= 0) return;
    final maxDist = w;

    for (var i = 0; i < _count; i++) {
      final z = _zs[i] - step;
      var respawn = z < 1;
      if (!respawn) {
        final size = _starSize * (1 - z / maxDist);
        final factor = maxDist / z;
        respawn =
            (_xs[i] * factor).abs() > w / 2 - size / 2 ||
            (_ys[i] * factor).abs() > h / 2 - size / 2;
      }
      if (respawn) {
        _xs[i] = _randomIn(-w / 2, w / 2);
        _ys[i] = _randomIn(-h / 2, h / 2);
        _zs[i] = maxDist;
      } else {
        _zs[i] = z;
      }
    }
    _writeTransforms();
  }

  /// Projects each star onto the screen; nearer stars draw bigger.
  void _writeTransforms() {
    final w = _size.width;
    final h = _size.height;
    if (w <= 0 || h <= 0 || _spriteDpr == 0) return;
    final maxDist = w;
    final anchor = _starSize * _spriteDpr / 2;

    for (var i = 0; i < _count; i++) {
      final z = _zs[i];
      final scale = (1 - z / maxDist).clamp(0.0, 1.0) / _spriteDpr;
      final factor = maxDist / z;
      final cx = _xs[i] * factor + w / 2;
      final cy = _ys[i] * factor + h / 2;
      final o = i * 4;
      _transforms[o] = scale;
      _transforms[o + 1] = 0;
      _transforms[o + 2] = cx - scale * anchor;
      _transforms[o + 3] = cy - scale * anchor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size != _size) {
          _size = size;
          _seed();
        }
        return RepaintBoundary(
          child: CustomPaint(size: size, painter: _StarPainter(this)),
        );
      },
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this._state) : super(repaint: _state._repaint);

  final _StarfieldBackgroundState _state;

  @override
  void paint(Canvas canvas, Size size) {
    final sprite = _state._sprite;
    if (sprite == null) return;
    canvas.drawRawAtlas(
      sprite,
      _state._transforms,
      _state._rects,
      null,
      null,
      null,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => true;
}
