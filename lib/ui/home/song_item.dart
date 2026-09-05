import 'package:flutter/material.dart';
import 'package:music_app/data/model/song.dart';

class SongItem extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onMorePressed;

  const SongItem({
    super.key,
    required this.song,
    required this.onTap,
    required this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 24.0, right: 16.0),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/ITunes_logo.png',
          image: song.image,
          width: 48,
          height: 48,
          imageErrorBuilder: (context, error, stackTrace) {
            return Image.asset('assets/ITunes_logo.png', width: 48, height: 48);
          },
        ),
      ),
      title: Text(song.title),
      subtitle: Text(song.artist),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz),
        onPressed: onMorePressed,
      ),
      onTap: onTap,
    );
  }
}
