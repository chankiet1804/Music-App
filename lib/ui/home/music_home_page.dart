import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/theme/theme.dart';
import 'package:music_app/ui/home/app_bottom_nav_bar.dart';
import 'package:music_app/ui/home/mini_player.dart';

class MusicHomePage extends StatelessWidget {
  const MusicHomePage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.house, size: 24)),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.music_note_2, size: 24)),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.heart, size: 24)),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.person, size: 24)),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final currentIndex = navigationShell.currentIndex;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Mysic App'),
        border: Border(bottom: BorderSide(color: tokens.barBorder, width: 0.0)),
      ),
      child: Column(
        children: [
          // Branch navigators are kept alive in an IndexedStack by go_router.
          Expanded(child: navigationShell),
          if (currentIndex == 0)
            const Padding(
              padding: EdgeInsets.only(
                left: AppNavBar.inset,
                right: AppNavBar.inset,
                bottom: AppSpacing.sm,
              ),
              child: MiniPlayer(),
            ),
          AppBottomNavBar(
            items: _navItems,
            currentIndex: currentIndex,
            // Re-tapping the active tab pops it back to its root.
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == currentIndex,
            ),
          ),
        ],
      ),
    );
  }
}
