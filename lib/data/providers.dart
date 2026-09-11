import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/data/repository/repository.dart';

final repositoryProvider = Provider<Repository>((ref) => DefaultRepository());

// Kept alive: song list is cached across tabs/screens.
final songsProvider = FutureProvider<List<Song>>((ref) async {
  final songs = await ref.watch(repositoryProvider).loadData();
  return songs ?? const [];
});

// Derived from the cached list instead of refetching.
final songByIdProvider = FutureProvider.autoDispose.family<Song?, String>((
  ref,
  id,
) async {
  final songs = await ref.watch(songsProvider.future);
  return songs.where((song) => song.id == id).firstOrNull;
});
