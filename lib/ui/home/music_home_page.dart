import 'package:flutter/cupertino.dart';
import 'package:music_app/theme/theme.dart';
import 'package:music_app/ui/discovery/discovery.dart';
import 'package:music_app/ui/favorite/favorite.dart';
import 'package:music_app/ui/home/app_bottom_nav_bar.dart';
import 'package:music_app/ui/home/home.dart';
import 'package:music_app/ui/home/mini_player.dart';
import 'package:music_app/ui/user/user.dart';

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.house, size: 24)),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.music_note_2, size: 24)),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.heart, size: 24)),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.person, size: 24)),
  ];

  final List<Widget> _tabs = [
    const HomeTabPage(),
    const DiscoveryTab(),
    const FavoriteTab(),
    const AccountTab(),
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Mysic App'),
        border: Border(bottom: BorderSide(color: tokens.barBorder, width: 0.0)),
      ),
      child: Column(
        children: [
          // IndexedStack keeps every tab alive, matching CupertinoTabScaffold.
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _tabs),
          ),
          if (_currentIndex == 0)
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
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        ],
      ),
    );
  }
}
