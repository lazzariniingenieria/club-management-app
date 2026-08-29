import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dev/presentation/screens/component_gallery_screen.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String devGallery = '/dev/gallery';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const Placeholder(),
    ),
    if (kDebugMode)
      GoRoute(
        path: AppRoutes.devGallery,
        builder: (context, state) => const ComponentGalleryScreen(),
      ),
  ],
);
