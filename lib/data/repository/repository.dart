import 'package:music_app/data/model/song.dart';
import 'package:music_app/data/source/source.dart';

abstract interface class Repository {
  Future<List<Song>?> loadData();
  Future<Song?> getSongById(String id);
}

class DefaultRepository implements Repository {
  final _localDataSource = LocalDataSource();
  final _remoteDataSource = RemoteDataSource();

  @override
  Future<List<Song>?> loadData() async {
    final remoteSongs = await _remoteDataSource.loadData();
    if (remoteSongs != null) return remoteSongs;
    return await _localDataSource.loadData();
  }

  @override
  Future<Song?> getSongById(String id) async {
    final songs = await loadData();
    return songs?.where((song) => song.id == id).firstOrNull;
  }
}
