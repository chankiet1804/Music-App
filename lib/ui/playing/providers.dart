import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/data/model/song.dart';
import 'package:rxdart/rxdart.dart';

class DurationState {
  DurationState({required this.progress, required this.buffered, this.total});

  final Duration progress;
  final Duration buffered;
  final Duration? total;
}

// Single app-wide player so playback survives leaving the Playing screen.
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

final playerControllerProvider = NotifierProvider<PlayerController, Song?>(
  PlayerController.new,
);

class PlayerController extends Notifier<Song?> {
  AudioPlayer get _player => ref.read(audioPlayerProvider);

  @override
  Song? build() => null;

  Future<void> load(Song song) async {
    // Same song already loaded: keep current position.
    if (state?.id == song.id) return;
    state = song;
    await _player.setUrl(song.source);
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration position) => _player.seek(position);
}

final playerStateProvider = StreamProvider<PlayerState>((ref) {
  return ref.watch(audioPlayerProvider).playerStateStream;
});

final durationStateProvider = StreamProvider<DurationState>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
    player.positionStream,
    player.playbackEventStream,
    (position, playbackEvent) => DurationState(
      progress: position,
      buffered: playbackEvent.bufferedPosition,
      total: playbackEvent.duration,
    ),
  );
});
