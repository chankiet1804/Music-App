import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/core/player/player_providers.dart';
import 'package:music_app/data/providers.dart';
import 'package:music_app/ui/home/song_item.dart';

class HomeTabPage extends ConsumerWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsProvider);

    return Scaffold(
      body: songsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load songs',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              TextButton(
                onPressed: () => ref.invalidate(songsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (songs) => ListView.separated(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return SongItem(
              song: song,
              onTap: () {
                ref.read(playerControllerProvider.notifier).load(song);
                context.go('/playing');
              },
              onMorePressed: () {
                // Handle more button press
              },
            );
          },
          separatorBuilder: (context, index) => const Divider(),
        ),
      ),
    );
  }
}
