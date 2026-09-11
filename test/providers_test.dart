import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/data/providers.dart';
import 'package:music_app/data/repository/repository.dart';

class FakeRepository implements Repository {
  FakeRepository(this.songs);

  final List<Song>? songs;
  int loadCount = 0;

  @override
  Future<List<Song>?> loadData() async {
    loadCount++;
    return songs;
  }
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

ProviderContainer _container(FakeRepository repository) {
  final container = ProviderContainer(
    overrides: [repositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('songsProvider returns songs from repository', () async {
    final container = _container(FakeRepository([_song('1'), _song('2')]));

    final songs = await container.read(songsProvider.future);

    expect(songs.map((song) => song.id), ['1', '2']);
  });

  test('songsProvider returns empty list when repository returns null', () async {
    final container = _container(FakeRepository(null));

    expect(await container.read(songsProvider.future), isEmpty);
  });

  test('songByIdProvider finds song and reuses cached list', () async {
    final repository = FakeRepository([_song('1'), _song('2')]);
    final container = _container(repository);

    await container.read(songsProvider.future);
    final subscription = container.listen(songByIdProvider('2'), (_, _) {});
    final song = await container.read(songByIdProvider('2').future);
    subscription.close();

    expect(song?.id, '2');
    expect(repository.loadCount, 1);
  });

  test('songByIdProvider returns null for unknown id', () async {
    final container = _container(FakeRepository([_song('1')]));

    final subscription = container.listen(songByIdProvider('x'), (_, _) {});
    final song = await container.read(songByIdProvider('x').future);
    subscription.close();

    expect(song, isNull);
  });
}
