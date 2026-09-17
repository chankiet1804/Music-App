import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/ui/discovery/discovery.dart';
import 'package:music_app/ui/favorite/favorite.dart';
import 'package:music_app/ui/home/home.dart';
import 'package:music_app/ui/home/music_home_page.dart';
import 'package:music_app/ui/playing/playing.dart';
import 'package:music_app/ui/user/user.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'home',
);
final GlobalKey<NavigatorState> _discoveryNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'discovery');
final GlobalKey<NavigatorState> _favoriteNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'favorite');
final GlobalKey<NavigatorState> _accountNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'account');

// Tab sub-routes belong inside their branch so the bottom bar stays visible.
// Only full-screen routes like /playing live on the root navigator.
final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: <RouteBase>[
    GoRoute(path: '/', redirect: (context, state) => '/home'),
    StatefulShellRoute.indexedStack(
      builder:
          (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell navigationShell,
          ) {
            return MusicHomePage(navigationShell: navigationShell);
          },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/home',
              builder: (BuildContext context, GoRouterState state) {
                return const HomeTabPage();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _discoveryNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/discovery',
              builder: (BuildContext context, GoRouterState state) {
                return const DiscoveryTab();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _favoriteNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/favorite',
              builder: (BuildContext context, GoRouterState state) {
                return const FavoriteTab();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _accountNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/account',
              builder: (BuildContext context, GoRouterState state) {
                return const AccountTab();
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/playing',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        return const Playing();
      },
    ),
  ],
);
