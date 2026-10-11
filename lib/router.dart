import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/core/auth/auth_providers.dart';
import 'package:music_app/ui/discovery/discovery.dart';
import 'package:music_app/ui/favorite/favorite.dart';
import 'package:music_app/ui/home/home.dart';
import 'package:music_app/ui/home/music_home_page.dart';
import 'package:music_app/ui/login/login.dart';
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

const String _loginPath = '/login';

// Built once: watches nothing, so the navigator keys are never recreated.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    // Signed-out users are kept on /login; signed-in users are kept off it.
    redirect: (BuildContext context, GoRouterState state) {
      final signedIn = ref.read(firebaseAuthProvider).currentUser != null;
      final atLogin = state.matchedLocation == _loginPath;
      if (!signedIn) return atLogin ? null : _loginPath;
      if (atLogin) return '/home';
      return null;
    },
    routes: _routes,
  );
  // Re-run redirect on sign-in / sign-out.
  ref.listen(authStateProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

// Tab sub-routes belong inside their branch so the bottom bar stays visible.
// Only full-screen routes like /playing live on the root navigator.
final List<RouteBase> _routes = <RouteBase>[
  GoRoute(path: '/', redirect: (context, state) => '/home'),
  GoRoute(
    path: _loginPath,
    parentNavigatorKey: _rootNavigatorKey,
    builder: (BuildContext context, GoRouterState state) {
      return const LoginPage();
    },
  ),
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
];
