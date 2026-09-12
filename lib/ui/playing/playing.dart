import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/theme/theme.dart';
import 'package:music_app/ui/playing/media_button_control.dart';
import 'package:music_app/ui/playing/providers.dart';

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
          timeLabelTextStyle: Theme.of(context).textTheme.labelSmall,
        );
      },
    );
  }

  Widget _mediaButtons() {
    final cs = Theme.of(context).colorScheme;
    final tokens = AppTokens.of(context);

    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          MediaButtonControl(
            function: () {
              ref.read(shuffleModeProvider.notifier).toggle();
            },
            icon: Icons.shuffle,
            color: ref.watch(shuffleModeProvider)
                ? cs.primary
                : tokens.textMuted,
            size: AppIconSize.sm,
          ),
          MediaButtonControl(
            function: () {
              ref.read(playerControllerProvider.notifier).prev();
              _imageAnimationController.reset();
            },
            icon: Icons.skip_previous,
            color: cs.onSurface,
            size: AppIconSize.md,
          ),
          _playButton(),
          MediaButtonControl(
            function: () {
              ref.read(playerControllerProvider.notifier).next();
              _imageAnimationController.reset();
            },
            icon: Icons.skip_next,
            color: cs.onSurface,
            size: AppIconSize.md,
          ),
          MediaButtonControl(
            function: () {
              ref.read(repeatModeProvider.notifier).toggle();
            },
            icon: _getRepeatIcon(),
            color: _getRepeatIconColor(context),
            size: AppIconSize.sm,
          ),
        ],
      ),
    );
  }

  IconData _getRepeatIcon() {
    return switch (ref.watch(repeatModeProvider)) {
      LoopMode.off => Icons.repeat,
      LoopMode.one => Icons.repeat_one,
      LoopMode.all => Icons.repeat,
    };
  }

  Color _getRepeatIconColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = AppTokens.of(context);
    return switch (ref.watch(repeatModeProvider)) {
      LoopMode.off => tokens.textMuted,
      LoopMode.one => cs.primary,
      LoopMode.all => cs.primary,
    };
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

  Widget _playButton() {
    return Consumer(
      builder: (context, ref, child) {
        final playerState = ref.watch(playerStateProvider).value;
        final controller = ref.read(playerControllerProvider.notifier);
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;

        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          return Container(
            margin: const EdgeInsets.all(AppSpacing.sm),
            width: AppIconSize.lg,
            height: AppIconSize.lg,
            child: const CircularProgressIndicator(),
          );
        } else if (playing != true) {
          return MediaButtonControl(
            function: () {
              controller.play();
            },
            icon: Icons.play_arrow,
            size: AppIconSize.lg,
            color: null,
          );
        } else if (processingState != ProcessingState.completed) {
          return MediaButtonControl(
            function: () {
              controller.pause();
            },
            icon: Icons.pause,
            size: AppIconSize.lg,
            color: null,
          );
        } else {
          return MediaButtonControl(
            function: () => {
              controller.seek(Duration.zero),
              _imageAnimationController.reset(),
            },
            icon: Icons.replay,
            size: AppIconSize.lg,
            color: null,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const delta = AppSpacing.huge;
    final radius = (screenWidth - delta) / 2;

    final song = ref.watch(playerControllerProvider);

    ref.listen(playerStateProvider, (_, next) {
      _syncRotation(_shouldSpin(next.value));
    });

    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Now Playing'),
        trailing: const IconButton(
          icon: Icon(Icons.more_horiz),
          onPressed: null,
        ),
        border: Border(bottom: BorderSide(color: tokens.barBorder, width: 0.0)),
      ),
      child: Scaffold(
        body: song == null
            ? Center(
                child: Text(
                  'No song is playing',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(song.album, style: theme.textTheme.labelSmall),
                    const SizedBox(height: AppSpacing.lg),
                    Text('_ ___ _', style: theme.textTheme.labelSmall),
                    const SizedBox(height: AppSpacing.xxl),
                    RotationTransition(
                      turns: Tween(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(_imageAnimationController),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/ITunes_logo.png',
                          image: song.image,
                          width: screenWidth - delta,
                          height: screenWidth - delta,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/ITunes_logo.png',
                              width: screenWidth - delta,
                              height: screenWidth - delta,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.huge,
                        bottom: AppSpacing.lg,
                      ),
                      child: SizedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share_outlined),
                              color: theme.colorScheme.primary,
                              onPressed: () {
                                // Handle share button press
                              },
                            ),
                            Column(
                              children: [
                                Text(
                                  song.title,
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  song.artist,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.favorite_outline),
                              color: theme.colorScheme.primary,
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.xxl,
                        left: AppSpacing.screenH,
                        right: AppSpacing.screenH,
                        bottom: AppSpacing.lg,
                      ),
                      child: _progressBar(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenH,
                      ),
                      child: _mediaButtons(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
