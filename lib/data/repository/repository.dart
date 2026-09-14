import 'package:flutter/foundation.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/data/source/source.dart';

abstract interface class Repository {
  Future<List<Song>?> loadData();
}

class DefaultRepository implements Repository {
  DefaultRepository({DataSource? remote, DataSource? local})
    : _remoteDataSource = remote ?? RemoteDataSource(),
      _localDataSource = local ?? LocalDataSource();

  final DataSource _remoteDataSource;
  final DataSource _localDataSource;

  @override
  Future<List<Song>?> loadData() async {
    // Any remote failure (offline, timeout, bad payload) falls back to local.
    try {
      final remoteSongs = await _remoteDataSource.loadData();
      if (remoteSongs != null) return remoteSongs;
    } catch (e) {
      debugPrint('Remote load failed, falling back to local: $e');
    }
    return await _localDataSource.loadData();
  }
}
