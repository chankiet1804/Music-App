import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/core/player/player_providers.dart';
import 'package:music_app/shared/widgets/media_button_control.dart';
import 'package:music_app/shared/widgets/play_pause_button.dart';
import 'package:music_app/theme/theme.dart';

class Playing extends ConsumerStatefulWidget {
  const Playing({super.key});

  @override
  ConsumerState<Playing> createState() => _PlayingState();
}

class _PlayingState extends ConsumerState<Playing>
    with SingleTickerProviderStateMixin {
  late AnimationController _imageAnimationController;

  @override
  void initState() {
    super.initState();
    _imageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );
    _syncRotation(_shouldSpin(ref.read(playerStateProvider).value));
  }

  @override
  void dispose() {
    _imageAnimationController.dispose();
    super.dispose();
  }

  Widget _header(String title) {
    final cs = Theme.of(context).colorScheme;
    final tokens = AppTokens.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          MediaButtonControl(
            function: () =>
                context.canPop() ? context.pop() : context.go('/'),
            svgAsset: AppIcons.arrowLeft,
            color: cs.onSurface,
            size: AppIconSize.sm,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          MediaButtonControl(
            function: () {},
            svgAsset: AppIcons.heart,
            color: tokens.textMuted,
            size: AppIconSize.sm,
          ),
        ],
      ),
    );
  }

  Widget _progressBar() {
    return Consumer(
      builder: (context, ref, child) {
        final cs = Theme.of(context).colorScheme;
        final tokens = AppTokens.of(context);
        final durationState = ref.watch(durationStateProvider).value;
        final progress = durationState?.progress ?? Duration.zero;
        final buffered = durationState?.buffered ?? Duration.zero;
        final total = durationState?.total ?? Duration.zero;

        return ProgressBar(
          progress: progress,
          buffered: buffered,
          total: total,
          onSeek: (duration) {
            ref.read(playerControllerProvider.notifier).seek(duration);
          },
          barHeight: AppBorders.progressBar,
          baseBarColor: cs.onSurface,
          progressBarColor: cs.primary,
          bufferedBarColor: tokens.textMuted,
          thumbColor: cs.primary,
          thumbRadius: AppBorders.progressBar,
          thumbGlowRadius: AppSpacing.lg,
          timeLabelLocation: TimeLabelLocation.below,
          timeLabelPadding: AppSpacing.xs,
          timeLabelTextStyle: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: cs.onSurface),
        );
      },
    );
  }

  Widget _mediaButtons() {
    final cs = Theme.of(context).colorScheme;
    final repeatMode = ref.watch(repeatModeProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MediaButtonControl(
          function: () {
            ref.read(shuffleModeProvider.notifier).toggle();
          },
          svgAsset: AppIcons.shuffle,
          color: ref.watch(shuffleModeProvider) ? cs.primary : cs.onSurface,
          size: AppIconSize.sm,
        ),
        MediaButtonControl(
          function: () {
            ref.read(playerControllerProvider.notifier).prev();
          },
          svgAsset: AppIcons.skipBack,
          color: cs.onSurface,
          size: AppIconSize.sm,
        ),
        PlayPauseButton(
          size: AppIconSize.sm,
          filled: true,
          onReplay: _imageAnimationController.reset,
        ),
        MediaButtonControl(
          function: () {
            ref.read(playerControllerProvider.notifier).next();
          },
          svgAsset: AppIcons.skipForward,
          color: cs.onSurface,
          size: AppIconSize.sm,
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            MediaButtonControl(
              function: () {
                ref.read(repeatModeProvider.notifier).toggle();
              },
              svgAsset: AppIcons.repeat,
              color: repeatMode == LoopMode.off ? cs.onSurface : cs.primary,
              size: AppIconSize.sm,
            ),
            // Feather has no repeat-one glyph, so mark it with a badge.
            if (repeatMode == LoopMode.one)
              IgnorePointer(
                child: Text(
                  '1',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 9,
                    fontWeight: AppFont.semiBold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _syncRotation(bool playing) {
    if (playing) {
      if (!_imageAnimationController.isAnimating) {
        _imageAnimationController.repeat();
      }
    } else {
      _imageAnimationController.stop();
    }
  }

  bool _shouldSpin(PlayerState? state) =>
      (state?.playing ?? false) &&
      state?.processingState != ProcessingState.completed &&
      state?.processingState != ProcessingState.loading;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth - 2 * (AppSpacing.screenH + AppSpacing.md);

    final song = ref.watch(playerControllerProvider);

    ref.listen(playerStateProvider, (_, next) {
      _syncRotation(_shouldSpin(next.value));
    });

    // Covers manual skips and native auto-advance alike.
    ref.listen(playerControllerProvider, (prev, next) {
      if (prev?.id != next?.id) _imageAnimationController.reset();
    });

    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(
              song == null
                  ? 'Now Playing'
                  : (song.album.isNotEmpty ? song.album : song.title),
            ),
            Expanded(
              child: song == null
                  ? Center(
                      child: Text(
                        'No song is playing',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: tokens.textMuted,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        const Spacer(),
                        RotationTransition(
                          turns: Tween(
                            begin: 0.0,
                            end: 1.0,
                          ).animate(_imageAnimationController),
                          child: ClipOval(
                            child: FadeInImage.assetNetwork(
                              placeholder: 'assets/ITunes_logo.png',
                              image: song.image,
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                              imageErrorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/ITunes_logo.png',
                                  width: imageSize,
                                  height: imageSize,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenH,
                          ),
                          child: Column(
                            children: [
                              Text(
                                song.title,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: AppFont.regular,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                song.artist,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: tokens.textMuted,
                                  fontWeight: AppFont.regular,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenH,
                          ),
                          child: _progressBar(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: _mediaButtons(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
