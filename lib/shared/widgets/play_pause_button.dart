import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/core/player/player_providers.dart';
import 'package:music_app/shared/widgets/media_button_control.dart';
import 'package:music_app/theme/theme.dart';

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
        icon: Icons.play_arrow,
        size: size,
        color: null,
      );
    } else if (processingState != ProcessingState.completed) {
      return MediaButtonControl(
        function: controller.pause,
        icon: Icons.pause,
        size: size,
        color: null,
      );
    } else {
      return MediaButtonControl(
        function: () {
          controller.seek(Duration.zero);
          onReplay?.call();
        },
        icon: Icons.replay,
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
    final cs = Theme.of(context).colorScheme;

    final Widget child;
    final VoidCallback? onTap;
    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      onTap = null;
      child = SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
      );
    } else if (playing != true) {
      onTap = controller.play;
      child = Icon(
        Icons.play_arrow_rounded,
        color: cs.onPrimary,
        size: size * 1.5,
      );
    } else if (processingState != ProcessingState.completed) {
      onTap = controller.pause;
      child = SvgPicture.asset(
        AppIcons.pause,
        height: size * 1.125,
        colorFilter: ColorFilter.mode(cs.onPrimary, BlendMode.srcIn),
      );
    } else {
      onTap = () {
        controller.seek(Duration.zero);
        onReplay?.call();
      };
      child = Icon(
        Icons.replay_rounded,
        color: cs.onPrimary,
        size: size * 1.5,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: cs.primary.withValues(alpha: 0.35), blurRadius: 47),
        ],
      ),
      child: Material(
        color: cs.primary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: _filledDiameter,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
