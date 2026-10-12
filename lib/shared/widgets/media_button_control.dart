import 'package:flutter/widgets.dart';
import 'package:music_app/theme/theme.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class MediaButtonControl extends StatelessWidget {
  const MediaButtonControl({
    super.key,
    required this.function,
    required this.icon,
    required this.color,
    required this.size,
  });

  final void Function()? function;
  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? ShadTheme.of(context).colorScheme.primary;
    final extent = size + 2 * AppSpacing.sm;

    return ShadIconButton.ghost(
      onPressed: function,
      width: extent,
      height: extent,
      padding: EdgeInsets.zero,
      iconSize: size,
      foregroundColor: color,
      hoverForegroundColor: color,
      pressedForegroundColor: color,
      icon: Icon(icon, color: color, size: size),
    );
  }
}
