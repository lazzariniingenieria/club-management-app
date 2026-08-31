import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_pending_screen.dart';
import '../../features/admin/presentation/screens/admin_profile_screen.dart';
import '../../features/admin/presentation/widgets/admin_shell.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dev/presentation/screens/component_gallery_screen.dart';
import '../../features/member/presentation/screens/member_surface_pending_screen.dart';
import '../constants/app_strings.dart';
import 'app_routes.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: _redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberSurfacePending,
        builder: (context, state) => const MemberSurfacePendingScreen(),
      ),
      ..._adminPushRoutes,
      _adminShellRoute,
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.devGallery,
          builder: (context, state) => const ComponentGalleryScreen(),
        ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    if (AppRoutes.isDevRoute(location)) return null;

    return switch (authBloc.state) {
      AuthSessionUnknown() =>
        location == AppRoutes.splash ? null : AppRoutes.splash,
      AuthUnauthenticated() =>
        AppRoutes.isAuthRoute(location) ? null : AppRoutes.login,
      AuthAuthenticated(:final user) => _redirectForRole(user.role, location),
    };
  }

  static String? _redirectForRole(UserRole role, String location) {
    if (!role.usesAdminSurface) {
      return location == AppRoutes.memberSurfacePending
          ? null
          : AppRoutes.memberSurfacePending;
    }
    if (!AppRoutes.isAdminSurface(location)) return AppRoutes.adminHome;
    if (location.startsWith(AppRoutes.adminAdmins) && !role.canManageAdmins) {
      return AppRoutes.adminHome;
    }
    return null;
  }

  static final StatefulShellRoute _adminShellRoute =
      StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        AdminShell(navigationShell: navigationShell),
    branches: [
      _branch(
        AppRoutes.adminHome,
        const AdminPendingScreen(
          title: AppStrings.adminHomeTitle,
          message: AppStrings.adminHomePending,
          icon: Icons.dashboard_rounded,
        ),
      ),
      _branch(
        AppRoutes.adminReservations,
        const AdminPendingScreen(
          title: AppStrings.adminReservationsTitle,
          message: AppStrings.adminReservationsPending,
          icon: Icons.event_rounded,
        ),
      ),
      _branch(
        AppRoutes.adminPayments,
        const AdminPendingScreen(
          title: AppStrings.adminPaymentsTitle,
          message: AppStrings.adminPaymentsPending,
          icon: Icons.payments_rounded,
        ),
      ),
      _branch(AppRoutes.adminProfile, const AdminProfileScreen()),
    ],
  );

  static StatefulShellBranch _branch(String path, Widget screen) {
    return StatefulShellBranch(
      routes: [GoRoute(path: path, builder: (context, state) => screen)],
    );
  }

  static final List<GoRoute> _adminPushRoutes = [
    GoRoute(
      path: AppRoutes.adminMembers,
      builder: (context, state) => const AdminPendingScreen(
        title: AppStrings.adminMembersTitle,
        message: AppStrings.adminMembersPending,
        icon: Icons.groups_rounded,
      ),
    ),
    GoRoute(
      path: AppRoutes.adminCourts,
      builder: (context, state) => const AdminPendingScreen(
        title: AppStrings.adminCourtsTitle,
        message: AppStrings.adminCourtsPending,
        icon: Icons.sports_tennis_rounded,
      ),
    ),
    GoRoute(
      path: AppRoutes.adminAdmins,
      builder: (context, state) => const AdminPendingScreen(
        title: AppStrings.adminAdminsTitle,
        message: AppStrings.adminAdminsPending,
        icon: Icons.admin_panel_settings_rounded,
      ),
    ),
  ];
}
