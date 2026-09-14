import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MediaButtonControl extends StatefulWidget {
  const MediaButtonControl({
    super.key,
    required this.function,
    this.icon,
    this.svgAsset,
    required this.color,
    required this.size,
  }) : assert(icon != null || svgAsset != null);

  final void Function()? function;
  final IconData? icon;

  /// Takes precedence over [icon] when set.
  final String? svgAsset;
  final Color? color;
  final double? size;

  @override
  State<StatefulWidget> createState() => _MediaButtonControlState();
}

class _MediaButtonControlState extends State<MediaButtonControl> {
  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final svgAsset = widget.svgAsset;

    return IconButton(
      onPressed: widget.function,
      icon: svgAsset != null
          ? SvgPicture.asset(
              svgAsset,
              width: widget.size,
              height: widget.size,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            )
          : Icon(widget.icon, color: color, size: widget.size),
    );
  }
}
