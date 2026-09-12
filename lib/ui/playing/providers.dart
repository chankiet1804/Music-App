import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/data/providers.dart';
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
  final _random = Random();

  AudioPlayer get _player => ref.read(audioPlayerProvider);
  List<Song> get _songs => ref.read(songsProvider).value ?? const [];

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

  Future<void> next() => _skip(1);

  Future<void> prev() => _skip(-1);

  Future<void> _skip(int step) async {
    final songs = _songs;
    if (songs.isEmpty) return;
    final index = songs.indexWhere((s) => s.id == state?.id);
    final target = ref.read(shuffleModeProvider)
        ? _randomIndex(songs.length, index)
        : (index == -1 ? 0 : (index + step) % songs.length);
    await load(songs[target]);
    // Not awaited: just_audio's play() completes only when playback stops.
    _player.play();
  }

  // Random pick that avoids repeating the current song when possible.
  int _randomIndex(int length, int current) {
    if (length == 1 || current == -1) return _random.nextInt(length);
    final offset = 1 + _random.nextInt(length - 1);
    return (current + offset) % length;
  }
}

final shuffleModeProvider = NotifierProvider<ShuffleModeController, bool>(
  ShuffleModeController.new,
);

class ShuffleModeController extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
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
