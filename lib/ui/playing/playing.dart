import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/ui/playing/audio_player_manager.dart';
import 'package:music_app/ui/playing/media_button_control.dart';
import 'package:music_app/ui/playing/viewmodal.dart';

class Playing extends StatefulWidget {
  const Playing({super.key, required this.songId});

  final String songId;

  @override
  State<Playing> createState() => _PlayingState();
}

class _PlayingState extends State<Playing> with SingleTickerProviderStateMixin {
  final _viewModel = PlayingViewModel();
  late final Future<Song?> _songFuture;

  late AnimationController _imageAnimationController;

  AudioPlayerManager? _audioPlayerManager;

  @override
  void initState() {
    super.initState();
    _songFuture = _viewModel.loadSong(widget.songId).then((song) {
      if (song != null) {
        _audioPlayerManager = AudioPlayerManager(songUrl: song.source)..init();
      }
      return song;
    });
    _imageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12000),
    );
  }

  @override
  void dispose() {
    _audioPlayerManager?.player.dispose();
    _imageAnimationController.dispose();
    super.dispose();
  }

  StreamBuilder<DurationState> _progressBar() {
    return StreamBuilder<DurationState>(
      stream: _audioPlayerManager?.durationState,
      builder: (context, snapshot) {
        final durationState = snapshot.data;
        final progress = durationState?.progress ?? Duration.zero;
        final buffered = durationState?.buffered ?? Duration.zero;
        final total = durationState?.total ?? Duration.zero;

        return ProgressBar(
          progress: progress,
          buffered: buffered,
          total: total,
          onSeek: (duration) {
            _audioPlayerManager?.player.seek(duration);
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

  StreamBuilder<PlayerState> _playButton() {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayerManager?.player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
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
            function: () {
              _audioPlayerManager?.player.play();
            },
            icon: Icons.play_arrow,
            size: 48.0,
            color: null,
          );
        } else if (processingState != ProcessingState.completed) {
          return MediaButtonControl(
            function: () {
              _audioPlayerManager?.player.pause();
            },
            icon: Icons.pause,
            size: 48.0,
            color: null,
          );
        } else {
          return MediaButtonControl(
            function: () {
              _audioPlayerManager?.player.seek(Duration.zero);
            },
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
        body: FutureBuilder<Song?>(
          future: _songFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final song = snapshot.data;
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
