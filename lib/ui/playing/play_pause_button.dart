import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/theme/theme.dart';
import 'package:music_app/ui/playing/media_button_control.dart';
import 'package:music_app/ui/playing/providers.dart';

/// Play/pause/replay button driven by [playerStateProvider]. Shared between
/// the full [Playing] screen and the mini player, sized via [size].
class PlayPauseButton extends ConsumerWidget {
  const PlayPauseButton({super.key, this.size = AppIconSize.lg, this.onReplay});

  final double size;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider).value;
    final controller = ref.read(playerControllerProvider.notifier);
    final processingState = playerState?.processingState;
    final playing = playerState?.playing;

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
}
