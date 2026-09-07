import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/ui/home/music_home_page.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MusicHomePage();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'details',
          builder: (BuildContext context, GoRouterState state) {
            return const Placeholder();
          },
        ),
      ],
    ),
  ],
);
