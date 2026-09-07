import 'package:flutter/material.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/ui/playing/viewmodal.dart';

class Playing extends StatefulWidget {
  const Playing({super.key, required this.songId});

  final String songId;

  @override
  State<Playing> createState() => _PlayingState();
}

class _PlayingState extends State<Playing> {
  final _viewModel = PlayingViewModel();
  late final Future<Song?> _songFuture;

  @override
  void initState() {
    super.initState();
    _songFuture = _viewModel.loadSong(widget.songId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Song?>(
        future: _songFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final song = snapshot.data;
          if (song == null) {
            return const Center(child: Text('Song not found'));
          }
          return Center(child: Text(song.title));
        },
      ),
    );
  }
}
