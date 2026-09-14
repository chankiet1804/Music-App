import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/data/repository/repository.dart';
import 'package:music_app/data/source/source.dart';

class FakeDataSource implements DataSource {
  FakeDataSource({this.songs, this.error});

  final List<Song>? songs;
  final Object? error;
  int loadCount = 0;

  @override
  Future<List<Song>?> loadData() async {
    loadCount++;
    if (error != null) throw error!;
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

Map<String, dynamic> _songJson(String id) => {
  'id': id,
  'title': 'Title $id',
  'album': 'Album',
  'artist': 'Artist',
  'source': 'https://example.com/$id.mp3',
  'image': 'https://example.com/$id.png',
  'duration': 180,
};

void main() {
  group('DefaultRepository', () {
    test('uses remote songs when available', () async {
      final remote = FakeDataSource(songs: [_song('r1')]);
      final local = FakeDataSource(songs: [_song('l1')]);

      final songs = await DefaultRepository(
        remote: remote,
        local: local,
      ).loadData();

      expect(songs?.map((s) => s.id), ['r1']);
      expect(local.loadCount, 0);
    });

    test('falls back to local when remote returns null', () async {
      final songs = await DefaultRepository(
        remote: FakeDataSource(),
        local: FakeDataSource(songs: [_song('l1')]),
      ).loadData();

      expect(songs?.map((s) => s.id), ['l1']);
    });

    test('falls back to local when remote throws', () async {
      final songs = await DefaultRepository(
        remote: FakeDataSource(error: const SocketException('offline')),
        local: FakeDataSource(songs: [_song('l1')]),
      ).loadData();

      expect(songs?.map((s) => s.id), ['l1']);
    });

    test('rethrows when local also fails', () async {
      final repository = DefaultRepository(
        remote: FakeDataSource(error: const SocketException('offline')),
        local: FakeDataSource(error: const FormatException('bad asset')),
      );

      expect(repository.loadData(), throwsFormatException);
    });
  });

  group('RemoteDataSource', () {
    test('parses songs on 200', () async {
      final client = MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'songs': [_songJson('1'), _songJson('2')],
            }),
          ),
          200,
        ),
      );

      final songs = await RemoteDataSource(client: client).loadData();

      expect(songs?.map((s) => s.id), ['1', '2']);
    });

    test('returns null on non-200', () async {
      final client = MockClient((_) async => http.Response('error', 500));

      expect(await RemoteDataSource(client: client).loadData(), isNull);
    });
  });
}
