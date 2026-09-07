import 'package:music_app/data/model/song.dart';
import 'package:music_app/data/repository/repository.dart';

class PlayingViewModel {
  final _repository = DefaultRepository();

  Future<Song?> loadSong(String id) => _repository.getSongById(id);
}
