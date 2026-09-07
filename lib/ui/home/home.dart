import 'package:flutter/material.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/ui/home/song_item.dart';
import 'package:music_app/ui/home/viewmodal.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  List<Song> songs = [];
  late MusicAppViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MusicAppViewModel();
    _viewModel.loadSongs();
    observeData();
  }

  @override
  void dispose() {
    _viewModel.songStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: songs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return SongItem(
                  song: song,
                  onTap: () {
                    // Handle song tap
                  },
                  onMorePressed: () {
                    // Handle more button press
                  },
                );
              },
              separatorBuilder: (context, index) => const Divider(
                color: Colors.grey,
                thickness: 1.0,
                indent: 24,
                endIndent: 24,
              ),
            ),
    );
  }

  void observeData() {
    _viewModel.songStream.stream.listen((data) {
      setState(() {
        songs.addAll(data);
      });
    });
  }
}
