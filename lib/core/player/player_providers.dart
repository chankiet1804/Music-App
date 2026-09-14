import 'package:flutter/foundation.dart';
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
  // Skip broken sources instead of stalling the queue.
  final player = AudioPlayer(maxSkipsOnError: 3);
  ref.onDispose(player.dispose);
  return player;
});

// Single place mapping Song <-> player source; swap tag to MediaItem for
// background playback.
AudioSource _sourceOf(Song song) =>
    AudioSource.uri(Uri.parse(song.source), tag: song);

Song? _songOf(IndexedAudioSource? source) => switch (source?.tag) {
  final Song song => song,
  _ => null,
};

final playerControllerProvider = NotifierProvider<PlayerController, Song?>(
  PlayerController.new,
);

/// Sends commands to the player and mirrors its current song. The queue,
/// auto-advance, shuffle order and looping are owned by the player itself.
class PlayerController extends Notifier<Song?> {
  AudioPlayer get _player => ref.read(audioPlayerProvider);

  @override
  Song? build() {
    final player = ref.watch(audioPlayerProvider);
    final sub = player.sequenceStateStream.listen(
      (sequence) => state = _songOf(sequence.currentSource),
    );
    ref.onDispose(sub.cancel);
    return _songOf(player.sequenceState.currentSource);
  }

  /// Loads [queue] and selects [index] without starting playback.
  Future<void> load(List<Song> queue, int index) async {
    final sequence = _player.sequenceState;
    if (_isLoaded(sequence, queue)) {
      // Same song already loaded: keep current position.
      if (sequence.currentIndex == index) return;
      await _player.seek(Duration.zero, index: index);
      return;
    }
    try {
      await _player.setAudioSources([
        for (final song in queue) _sourceOf(song),
      ], initialIndex: index);
    } on PlayerInterruptedException catch (e) {
      debugPrint('Queue load interrupted: $e');
    } on PlayerException catch (e) {
      debugPrint('Queue load failed: $e');
    }
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> next() => _skip(1);

  Future<void> prev() => _skip(-1);

  // Manual skips always wrap and ignore repeat-one, unlike seekToNext().
  Future<void> _skip(int step) async {
    final sequence = _player.sequenceState;
    final current = sequence.currentIndex;
    if (sequence.sequence.isEmpty || current == null) return;
    final order = sequence.shuffleModeEnabled
        ? sequence.shuffleIndices
        : List.generate(sequence.sequence.length, (i) => i);
    final target = order[(order.indexOf(current) + step) % order.length];
    await _player.seek(Duration.zero, index: target);
    // Not awaited: just_audio's play() completes only when playback stops.
    _player.play();
  }

  bool _isLoaded(SequenceState sequence, List<Song> queue) {
    final loaded = sequence.sequence;
    if (loaded.length != queue.length) return false;
    for (var i = 0; i < queue.length; i++) {
      if (_songOf(loaded[i])?.id != queue[i].id) return false;
    }
    return queue.isNotEmpty;
  }
}

final shuffleModeProvider = NotifierProvider<ShuffleModeController, bool>(
  ShuffleModeController.new,
);

class ShuffleModeController extends Notifier<bool> {
  AudioPlayer get _player => ref.read(audioPlayerProvider);

  @override
  bool build() => false;

  Future<void> toggle() async {
    state = !state;
    // Fresh permutation starting from the current song.
    if (state) await _player.shuffle();
    await _player.setShuffleModeEnabled(state);
  }
}

final repeatModeProvider = NotifierProvider<RepeatModeController, LoopMode>(
  RepeatModeController.new,
);

class RepeatModeController extends Notifier<LoopMode> {
  AudioPlayer get _player => ref.read(audioPlayerProvider);

  @override
  LoopMode build() => LoopMode.off;

  void toggle() {
    state = switch (state) {
      LoopMode.off => LoopMode.one,
      LoopMode.one => LoopMode.all,
      LoopMode.all => LoopMode.off,
    };
    _player.setLoopMode(state);
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
