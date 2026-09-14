import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/core/player/player_providers.dart';
import 'package:music_app/data/model/song.dart';

/// Emulates the player-owned queue: sequence, current index, shuffle order.
class FakeAudioPlayer extends Fake implements AudioPlayer {
  final _sequenceController = StreamController<SequenceState>.broadcast(
    sync: true,
  );
  SequenceState _sequence = SequenceState(
    sequence: const [],
    currentIndex: null,
    shuffleIndices: const [],
    shuffleModeEnabled: false,
    loopMode: LoopMode.off,
  );

  final calls = <String>[];
  int loadCount = 0;
  int? lastInitialIndex;
  int? lastSeekIndex;
  Duration? lastSeek;
  int playCount = 0;
  int pauseCount = 0;
  LoopMode? lastLoopMode;

  void _emit(SequenceState sequence) {
    _sequence = sequence;
    _sequenceController.add(sequence);
  }

  /// Simulates the native player advancing on its own.
  void advanceTo(int index) => _emit(_sequence.copyWith(currentIndex: index));

  @override
  SequenceState get sequenceState => _sequence;

  @override
  Stream<SequenceState> get sequenceStateStream => _sequenceController.stream;

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> audioSources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    loadCount++;
    lastInitialIndex = initialIndex;
    final sources = audioSources.cast<IndexedAudioSource>();
    _emit(
      _sequence.copyWith(
        sequence: sources,
        currentIndex: initialIndex ?? 0,
        shuffleIndices: List.generate(sources.length, (i) => i),
      ),
    );
    return null;
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    lastSeek = position;
    lastSeekIndex = index;
    if (index != null) advanceTo(index);
  }

  @override
  Future<void> shuffle() async {
    calls.add('shuffle');
    // Deterministic order for tests: reversed.
    _emit(
      _sequence.copyWith(
        shuffleIndices: List.generate(
          _sequence.sequence.length,
          (i) => _sequence.sequence.length - 1 - i,
        ),
      ),
    );
  }

  @override
  Future<void> setShuffleModeEnabled(bool enabled) async {
    calls.add('setShuffleModeEnabled($enabled)');
    _emit(_sequence.copyWith(shuffleModeEnabled: enabled));
  }

  @override
  Future<void> setLoopMode(LoopMode mode) async {
    lastLoopMode = mode;
    _emit(_sequence.copyWith(loopMode: mode));
  }

  @override
  Future<void> play() async => playCount++;

  @override
  Future<void> pause() async => pauseCount++;

  @override
  Future<void> dispose() => _sequenceController.close();
}

Song _song(String id) => Song(
  id: id,
  title: 'Title $id',
  album: 'Album',
  artist: 'Artist',
  source: 'https://example.com/$id.mp3',
  image: 'https://example.com/$id.png',
  duration: 180,
);

(ProviderContainer, FakeAudioPlayer) _setup() {
  final player = FakeAudioPlayer();
  final container = ProviderContainer(
    overrides: [audioPlayerProvider.overrideWithValue(player)],
  );
  addTearDown(container.dispose);
  // Keep the controller alive so it mirrors the sequence stream.
  container.listen(playerControllerProvider, (_, _) {});
  return (container, player);
}

void main() {
  final songs = [_song('1'), _song('2'), _song('3')];

  group('PlayerController.load', () {
    test('loads queue in order and selects index', () async {
      final (container, player) = _setup();

      await container.read(playerControllerProvider.notifier).load(songs, 1);

      expect(player.loadCount, 1);
      expect(player.lastInitialIndex, 1);
      expect(
        player.sequenceState.sequence.map((s) => (s.tag as Song).id),
        ['1', '2', '3'],
      );
      expect(container.read(playerControllerProvider), songs[1]);
      expect(player.playCount, 0);
    });

    test('same queue and index keeps current position', () async {
      final (container, player) = _setup();
      final controller = container.read(playerControllerProvider.notifier);

      await controller.load(songs, 1);
      await controller.load(songs, 1);

      expect(player.loadCount, 1);
      expect(player.lastSeekIndex, isNull);
    });

    test('same queue with another index seeks instead of reloading', () async {
      final (container, player) = _setup();
      final controller = container.read(playerControllerProvider.notifier);

      await controller.load(songs, 0);
      await controller.load(songs, 2);

      expect(player.loadCount, 1);
      expect(player.lastSeekIndex, 2);
      expect(container.read(playerControllerProvider), songs[2]);
    });

    test('different queue reloads sources', () async {
      final (container, player) = _setup();
      final controller = container.read(playerControllerProvider.notifier);

      await controller.load(songs, 0);
      await controller.load([songs[2], songs[0]], 0);

      expect(player.loadCount, 2);
      expect(container.read(playerControllerProvider), songs[2]);
    });
  });

  group('PlayerController', () {
    test('mirrors native auto-advance', () async {
      final (container, player) = _setup();
      await container.read(playerControllerProvider.notifier).load(songs, 0);

      player.advanceTo(1);

      expect(container.read(playerControllerProvider), songs[1]);
    });

    test('next moves forward and starts playback', () async {
      final (container, player) = _setup();
      final controller = container.read(playerControllerProvider.notifier);
      await controller.load(songs, 0);

      await controller.next();

      expect(player.lastSeekIndex, 1);
      expect(player.lastSeek, Duration.zero);
      expect(player.playCount, 1);
      expect(container.read(playerControllerProvider), songs[1]);
    });

    test('next on last song wraps to first', () async {
      final (container, player) = _setup();
      final controller = container.read(playerControllerProvider.notifier);
      await controller.load(songs, 2);

      await controller.next();

      expect(player.lastSeekIndex, 0);
    });

    test('prev on first song wraps to last', () async {
      final (container, player) = _setup();
      final controller = container.read(playerControllerProvider.notifier);
      await controller.load(songs, 0);

      await controller.prev();

      expect(player.lastSeekIndex, 2);
    });

    test('next follows shuffle order when shuffle is on', () async {
      final (container, player) = _setup();
      final controller = container.read(playerControllerProvider.notifier);
      await controller.load(songs, 2);
      await container.read(shuffleModeProvider.notifier).toggle();

      // Fake shuffle order is [2, 1, 0].
      await controller.next();

      expect(player.lastSeekIndex, 1);
    });

    test('next still advances when repeat one is on', () async {
      final (container, player) = _setup();
      final controller = container.read(playerControllerProvider.notifier);
      await controller.load(songs, 0);
      container.read(repeatModeProvider.notifier).toggle();

      await controller.next();

      expect(player.lastSeekIndex, 1);
    });

    test('next with empty queue does nothing', () async {
      final (container, player) = _setup();

      await container.read(playerControllerProvider.notifier).next();

      expect(player.lastSeekIndex, isNull);
      expect(player.playCount, 0);
      expect(container.read(playerControllerProvider), isNull);
    });

    test('play, pause and seek delegate to player', () async {
      final (container, player) = _setup();
      final controller = container.read(playerControllerProvider.notifier);

      await controller.play();
      await controller.pause();
      await controller.seek(const Duration(seconds: 42));

      expect(player.playCount, 1);
      expect(player.pauseCount, 1);
      expect(player.lastSeek, const Duration(seconds: 42));
    });
  });

  test('ShuffleModeController reshuffles before enabling', () async {
    final (container, player) = _setup();
    final controller = container.read(shuffleModeProvider.notifier);

    await controller.toggle();
    expect(container.read(shuffleModeProvider), isTrue);
    await controller.toggle();
    expect(container.read(shuffleModeProvider), isFalse);

    expect(player.calls, [
      'shuffle',
      'setShuffleModeEnabled(true)',
      'setShuffleModeEnabled(false)',
    ]);
  });

  test('RepeatModeController passes each mode to player', () {
    final (container, player) = _setup();
    final controller = container.read(repeatModeProvider.notifier);

    for (final mode in [LoopMode.one, LoopMode.all, LoopMode.off]) {
      controller.toggle();
      expect(container.read(repeatModeProvider), mode);
      expect(player.lastLoopMode, mode);
    }
  });
}
