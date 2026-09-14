import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/core/player/player_providers.dart';
import 'package:music_app/shared/widgets/media_button_control.dart';
import 'package:music_app/shared/widgets/play_pause_button.dart';
import 'package:music_app/theme/theme.dart';

/// Persistent mini player shown above [AppBottomNavBar] while a song is
/// loaded. Tapping it opens the full [Playing] screen; the transport buttons
/// mirror the ones on that screen.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerControllerProvider);
    if (song == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.go('/playing'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: AppBorders.hairline,
              ),
            ),
            child: Row(
              children: [
                _Artwork(image: song.image),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                MediaButtonControl(
                  function: () {
                    ref.read(playerControllerProvider.notifier).prev();
                  },
                  icon: Icons.skip_previous,
                  color: theme.colorScheme.onSurface,
                  size: AppIconSize.sm,
                ),
                const PlayPauseButton(size: AppIconSize.md),
                MediaButtonControl(
                  function: () {
                    ref.read(playerControllerProvider.notifier).next();
                  },
                  icon: Icons.skip_next,
                  color: theme.colorScheme.onSurface,
                  size: AppIconSize.sm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;

    Widget art() => Image.network(
      image,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/ITunes_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: art(),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: art(),
          ),
        ],
      ),
    );
  }
}
