import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/core/player/player_providers.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/data/providers.dart';
import 'package:music_app/data/repository/repository.dart';

class FakeAudioPlayer extends Fake implements AudioPlayer {
  final urls = <String>[];
  int playCount = 0;
  int pauseCount = 0;
  Duration? lastSeek;
  LoopMode? lastLoopMode;

  @override
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    urls.add(url);
    return null;
  }

  @override
  Future<void> play() async => playCount++;

  @override
  Future<void> pause() async => pauseCount++;

  @override
  Future<void> seek(Duration? position, {int? index}) async =>
      lastSeek = position;

  @override
  Future<void> setLoopMode(LoopMode mode) async => lastLoopMode = mode;

  @override
  Future<void> dispose() async {}
}

class FakeRepository implements Repository {
  FakeRepository(this.songs);

  final List<Song> songs;

  @override
  Future<List<Song>?> loadData() async => songs;
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

Future<(ProviderContainer, FakeAudioPlayer)> _setup(List<Song> songs) async {
  final player = FakeAudioPlayer();
  final container = ProviderContainer(
    overrides: [
      audioPlayerProvider.overrideWithValue(player),
      repositoryProvider.overrideWithValue(FakeRepository(songs)),
    ],
  );
  addTearDown(container.dispose);
  // Controller reads the cached list synchronously, so load it first.
  await container.read(songsProvider.future);
  return (container, player);
}

void main() {
  final songs = [_song('1'), _song('2'), _song('3')];

  group('PlayerController', () {
    test('load sets current song and source', () async {
      final (container, player) = await _setup(songs);

      await container.read(playerControllerProvider.notifier).load(songs[1]);

      expect(container.read(playerControllerProvider), songs[1]);
      expect(player.urls, [songs[1].source]);
    });

    test('load same song again does not reload source', () async {
      final (container, player) = await _setup(songs);
      final controller = container.read(playerControllerProvider.notifier);

      await controller.load(songs[0]);
      await controller.load(songs[0]);

      expect(player.urls, hasLength(1));
    });

    test('next advances, wraps around and starts playback', () async {
      final (container, player) = await _setup(songs);
      final controller = container.read(playerControllerProvider.notifier);

      await controller.load(songs[0]);
      await controller.next();
      expect(container.read(playerControllerProvider), songs[1]);

      await controller.load(songs[2]);
      await controller.next();
      expect(container.read(playerControllerProvider), songs[0]);
      expect(player.playCount, 2);
    });

    test('prev from first song wraps to last', () async {
      final (container, _) = await _setup(songs);
      final controller = container.read(playerControllerProvider.notifier);

      await controller.load(songs[0]);
      await controller.prev();

      expect(container.read(playerControllerProvider), songs[2]);
    });

    test('prev without current song starts at first song', () async {
      final (container, _) = await _setup(songs);

      await container.read(playerControllerProvider.notifier).prev();

      expect(container.read(playerControllerProvider), songs[0]);
    });

    test('next with empty song list does nothing', () async {
      final (container, player) = await _setup(const []);

      await container.read(playerControllerProvider.notifier).next();

      expect(container.read(playerControllerProvider), isNull);
      expect(player.urls, isEmpty);
    });

    test('shuffle never repeats current song', () async {
      final twoSongs = [_song('a'), _song('b')];
      final (container, _) = await _setup(twoSongs);
      final controller = container.read(playerControllerProvider.notifier);
      container.read(shuffleModeProvider.notifier).toggle();

      await controller.load(twoSongs[0]);
      for (var i = 0; i < 5; i++) {
        final current = container.read(playerControllerProvider);
        await controller.next();
        expect(container.read(playerControllerProvider), isNot(current));
      }
    });

    test('play, pause and seek delegate to player', () async {
      final (container, player) = await _setup(songs);
      final controller = container.read(playerControllerProvider.notifier);

      await controller.play();
      await controller.pause();
      await controller.seek(const Duration(seconds: 42));

      expect(player.playCount, 1);
      expect(player.pauseCount, 1);
      expect(player.lastSeek, const Duration(seconds: 42));
    });
  });

  test('ShuffleModeController toggles on and off', () async {
    final (container, _) = await _setup(songs);
    final controller = container.read(shuffleModeProvider.notifier);

    expect(container.read(shuffleModeProvider), isFalse);
    controller.toggle();
    expect(container.read(shuffleModeProvider), isTrue);
    controller.toggle();
    expect(container.read(shuffleModeProvider), isFalse);
  });

  test('RepeatModeController cycles off -> one -> all -> off', () async {
    final (container, player) = await _setup(songs);
    final controller = container.read(repeatModeProvider.notifier);

    controller.toggle();
    expect(container.read(repeatModeProvider), LoopMode.one);
    expect(player.lastLoopMode, LoopMode.one);

    controller.toggle();
    expect(container.read(repeatModeProvider), LoopMode.all);
    expect(player.lastLoopMode, LoopMode.off);

    controller.toggle();
    expect(container.read(repeatModeProvider), LoopMode.off);
    expect(player.lastLoopMode, LoopMode.off);
  });
}
