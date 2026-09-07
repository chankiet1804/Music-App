import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/ui/home/music_home_page.dart';
import 'package:music_app/ui/playing/playing.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MusicHomePage();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'playing/:id',
          builder: (BuildContext context, GoRouterState state) {
            return Playing(songId: state.pathParameters['id']!);
          },
        ),
      ],
    ),
  ],
);
