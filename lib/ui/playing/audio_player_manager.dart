import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class DurationState {
  DurationState({required this.progress, required this.buffered, this.total});

  final Duration progress;
  final Duration buffered;
  final Duration? total;
}

class AudioPlayerManager {
  AudioPlayerManager({required this.songUrl});

  final player = AudioPlayer();
  Stream<DurationState>? durationState;
  String songUrl;

  void init() {
    durationState = Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
      player.positionStream,
      player.playbackEventStream,
      (position, playbackEvent) => DurationState(
        progress: position,
        buffered: playbackEvent.bufferedPosition,
        total: playbackEvent.duration,
      ),
    );
    player.setUrl(songUrl);
  }
}
