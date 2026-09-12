import 'package:flutter/material.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/theme/theme.dart';

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
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/ITunes_logo.png',
          image: song.image,
          width: AppIconSize.lg,
          height: AppIconSize.lg,
          imageErrorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/ITunes_logo.png',
              width: AppIconSize.lg,
              height: AppIconSize.lg,
            );
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
