import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/core/player/player_providers.dart';
import 'package:music_app/shared/widgets/media_button_control.dart';
import 'package:music_app/theme/theme.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Play/pause/replay button driven by [playerStateProvider]. Shared between
/// the full [Playing] screen and the mini player, sized via [size].
/// [filled] renders the glowing primary circle from the Playing design.
class PlayPauseButton extends ConsumerWidget {
  const PlayPauseButton({
    super.key,
    this.size = AppIconSize.lg,
    this.onReplay,
    this.filled = false,
  });

  final double size;
  final VoidCallback? onReplay;
  final bool filled;

  static const double _filledDiameter = 74;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider).value;
    final controller = ref.read(playerControllerProvider.notifier);
    final processingState = playerState?.processingState;
    final playing = playerState?.playing;

    if (filled) {
      return _buildFilled(context, processingState, playing, controller);
    }

    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (playing != true) {
      return MediaButtonControl(
        function: controller.play,
        icon: LucideIcons.play,
        size: size,
        color: null,
      );
    } else if (processingState != ProcessingState.completed) {
      return MediaButtonControl(
        function: controller.pause,
        icon: LucideIcons.pause,
        size: size,
        color: null,
      );
    } else {
      return MediaButtonControl(
        function: () {
          controller.seek(Duration.zero);
          onReplay?.call();
        },
        icon: LucideIcons.rotateCcw,
        size: size,
        color: null,
      );
    }
  }

  Widget _buildFilled(
    BuildContext context,
    ProcessingState? processingState,
    bool? playing,
    PlayerController controller,
  ) {
    final cs = ShadTheme.of(context).colorScheme;

    final Widget child;
    final VoidCallback? onTap;
    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      onTap = null;
      child = SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: cs.primaryForeground,
        ),
      );
    } else if (playing != true) {
      onTap = controller.play;
      child = Icon(LucideIcons.play, size: size * 1.25);
    } else if (processingState != ProcessingState.completed) {
      onTap = controller.pause;
      child = Icon(LucideIcons.pause, size: size * 1.25);
    } else {
      onTap = () {
        controller.seek(Duration.zero);
        onReplay?.call();
      };
      child = Icon(LucideIcons.rotateCcw, size: size * 1.25);
    }

    return ShadIconButton(
      onPressed: onTap,
      width: _filledDiameter,
      height: _filledDiameter,
      padding: EdgeInsets.zero,
      backgroundColor: cs.primary,
      hoverBackgroundColor: cs.primary,
      foregroundColor: cs.primaryForeground,
      hoverForegroundColor: cs.primaryForeground,
      decoration: const ShadDecoration(
        border: ShadBorder(
          radius: BorderRadius.all(Radius.circular(_filledDiameter / 2)),
        ),
      ),
      shadows: [
        BoxShadow(color: cs.primary.withValues(alpha: 0.35), blurRadius: 47),
      ],
      icon: child,
    );
  }
}
