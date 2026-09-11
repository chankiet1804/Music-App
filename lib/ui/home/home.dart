import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
              const Text('Failed to load songs'),
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
                context.go('/playing/${song.id}');
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
      ),
    );
  }
}
