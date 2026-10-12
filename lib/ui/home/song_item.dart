import 'package:flutter/widgets.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/shared/widgets/media_button_control.dart';
import 'package:music_app/theme/theme.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
    final theme = ShadTheme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.lg,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        child: Row(
          children: [
            ClipRRect(
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
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.title,
                  ),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.muted,
                  ),
                ],
              ),
            ),
            MediaButtonControl(
              function: onMorePressed,
              icon: LucideIcons.ellipsis,
              color: theme.colorScheme.mutedForeground,
              size: AppIconSize.sm,
            ),
          ],
        ),
      ),
    );
  }
}
