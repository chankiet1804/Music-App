import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/data/providers.dart';
import 'package:music_app/ui/playing/media_button_control.dart';
import 'package:music_app/ui/playing/providers.dart';

class Playing extends ConsumerStatefulWidget {
  const Playing({super.key, required this.songId});

  final String songId;

  @override
  ConsumerState<Playing> createState() => _PlayingState();
}

class _PlayingState extends ConsumerState<Playing>
    with SingleTickerProviderStateMixin {
  late AnimationController _imageAnimationController;

  @override
  void initState() {
    super.initState();
    ref.listenManual(songByIdProvider(widget.songId), (_, next) {
      final song = next.value;
      if (song != null) {
        ref.read(playerControllerProvider.notifier).load(song);
      }
    }, fireImmediately: true);
    _imageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12000),
    );
  }

  @override
  void dispose() {
    _imageAnimationController.dispose();
    super.dispose();
  }

  Widget _progressBar() {
    return Consumer(
      builder: (context, ref, child) {
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
          barHeight: 5.0,
        );
      },
    );
  }

  Widget _mediaButtons() {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          MediaButtonControl(
            function: () {
              null; // Implement previous track functionality
            },
            icon: Icons.shuffle,
            color: Colors.deepPurple,
            size: 24,
          ),
          MediaButtonControl(
            function: () {
              null; // Implement previous track functionality
            },
            icon: Icons.skip_previous,
            color: Colors.deepPurple,
            size: 36,
          ),
          _playButton(),
          MediaButtonControl(
            function: () {
              null; // Implement next track functionality
            },
            icon: Icons.skip_next,
            color: Colors.deepPurple,
            size: 36,
          ),
          MediaButtonControl(
            function: () {
              null; // Implement next track functionality
            },
            icon: Icons.repeat,
            color: Colors.deepPurple,
            size: 24,
          ),
        ],
      ),
    );
  }

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
            margin: const EdgeInsets.all(8.0),
            width: 48.0,
            height: 48.0,
            child: const CircularProgressIndicator(),
          );
        } else if (playing != true) {
          return MediaButtonControl(
            function: controller.play,
            icon: Icons.play_arrow,
            size: 48.0,
            color: null,
          );
        } else if (processingState != ProcessingState.completed) {
          return MediaButtonControl(
            function: controller.pause,
            icon: Icons.pause,
            size: 48.0,
            color: null,
          );
        } else {
          return MediaButtonControl(
            function: () => controller.seek(Duration.zero),
            icon: Icons.replay,
            size: 48.0,
            color: null,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const delta = 64.0;
    final radius = (screenWidth - delta) / 2;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Now Playing'),
        trailing: IconButton(icon: Icon(Icons.more_horiz), onPressed: null),
      ),
      child: Scaffold(
        body: ref.watch(songByIdProvider(widget.songId)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              const Center(child: Text('Failed to load song')),
          data: (song) {
            if (song == null) {
              return const Center(child: Text('Song not found'));
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(song.album),
                  const SizedBox(height: 16),
                  const Text('_ ___ _'),
                  const SizedBox(height: 32),
                  RotationTransition(
                    turns: Tween(
                      begin: 0.0,
                      end: 1.0,
                    ).animate(_imageAnimationController),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/images/placeholder.png',
                        image: song.image,
                        width: screenWidth - delta,
                        height: screenWidth - delta,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/placeholder.png',
                            width: screenWidth - delta,
                            height: screenWidth - delta,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 64.0, bottom: 16.0),
                    child: SizedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share_outlined),
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () {
                              // Handle share button press
                            },
                          ),
                          Column(
                            children: [
                              Text(
                                song.title,
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .color,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                song.artist,
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .color,
                                    ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite_outline),
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 32,
                      left: 24,
                      right: 24,
                      bottom: 16,
                    ),
                    child: _progressBar(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _mediaButtons(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
