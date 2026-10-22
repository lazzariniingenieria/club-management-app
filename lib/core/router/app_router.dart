import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_home_screen.dart';
import '../../features/admin/presentation/screens/admin_pending_screen.dart';
import '../../features/admin/presentation/screens/admin_profile_screen.dart';
import '../../features/admin/presentation/widgets/admin_shell.dart';
import '../../features/admins/presentation/screens/admin_form_args.dart';
import '../../features/admins/presentation/screens/admin_form_screen.dart';
import '../../features/admins/presentation/screens/admins_screen.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dev/presentation/screens/component_gallery_screen.dart';
import '../../features/family_groups/presentation/screens/family_group_picker_screen.dart';
import '../../features/family_groups/presentation/screens/family_group_screen.dart';
import '../../features/member/presentation/screens/member_surface_pending_screen.dart';
import '../../features/members/domain/entities/member.dart';
import '../../features/members/domain/entities/member_collection_filter.dart';
import '../../features/members/presentation/screens/member_form_screen.dart';
import '../../features/payments/domain/entities/payment_receipt.dart';
import '../../features/payments/presentation/screens/admin_payments_screen.dart';
import '../../features/payments/presentation/screens/member_ledger_screen.dart';
import '../../features/payments/presentation/screens/payment_member_picker_screen.dart';
import '../../features/payments/presentation/screens/register_payment_screen.dart';
import '../../features/reports/presentation/screens/payment_report_screen.dart';
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
      _branch(AppRoutes.adminHome, (context, state) => const AdminHomeScreen()),
      _branch(AppRoutes.adminPayments, _buildPaymentsScreen),
      _branch(
        AppRoutes.adminProfile,
        (context, state) => const AdminProfileScreen(),
      ),
    ],
  );

  static Widget _buildPaymentsScreen(
      BuildContext context, GoRouterState state) {
    return AdminPaymentsScreen(
      filter: MemberCollectionFilter.fromQueryValue(
        state.uri.queryParameters[AppRoutes.filterQueryParameter],
      ),
    );
  }

  static StatefulShellBranch _branch(
      String path, GoRouterWidgetBuilder builder) {
    return StatefulShellBranch(
      routes: [GoRoute(path: path, builder: builder)],
    );
  }

  static final List<GoRoute> _adminPushRoutes = [
    GoRoute(
      path: AppRoutes.adminMemberCreation,
      builder: (context, state) => const MemberFormScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminMemberEditionPattern,
      redirect: (context, state) =>
          state.extra is Member ? null : AppRoutes.adminPayments,
      builder: (context, state) =>
          MemberFormScreen(member: state.extra as Member),
    ),
    GoRoute(
      path: AppRoutes.adminPaymentMemberPicker,
      builder: (context, state) => const PaymentMemberPickerScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminPaymentReport,
      builder: (context, state) => const PaymentReportScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminMemberLedgerPattern,
      redirect: _requireMemberId,
      builder: (context, state) => MemberLedgerScreen(
        memberId: _memberIdOf(state)!,
        receipt: state.extra is PaymentReceipt
            ? state.extra as PaymentReceipt
            : null,
      ),
    ),
    GoRoute(
      path: AppRoutes.adminPaymentRegistrationPattern,
      redirect: _requireMemberId,
      builder: (context, state) =>
          RegisterPaymentScreen(memberId: _memberIdOf(state)!),
    ),
    GoRoute(
      path: AppRoutes.adminFamilyGroupCreationPattern,
      redirect: _requireMemberId,
      builder: (context, state) => FamilyGroupPickerScreen(
        mode: BuildGroupForMember(_memberIdOf(state)!),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminFamilyGroupPattern,
      redirect: _requireFamilyGroupId,
      builder: (context, state) =>
          FamilyGroupScreen(familyGroupId: _familyGroupIdOf(state)!),
    ),
    GoRoute(
      path: AppRoutes.adminFamilyGroupMemberPickerPattern,
      redirect: _requireFamilyGroupId,
      builder: (context, state) => FamilyGroupPickerScreen(
        mode: AddToFamilyGroup(_familyGroupIdOf(state)!),
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
      builder: (context, state) => const AdminsScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminAdminCreation,
      redirect: _requireAdminFormArgs,
      builder: (context, state) =>
          AdminFormScreen(args: state.extra as AdminFormArgs),
    ),
    GoRoute(
      path: AppRoutes.adminAdminEditionPattern,
      redirect: _requireAdminFormArgs,
      builder: (context, state) =>
          AdminFormScreen(args: state.extra as AdminFormArgs),
    ),
  ];

  static int? _memberIdOf(GoRouterState state) => int.tryParse(
        state.pathParameters[AppRoutes.memberIdPathParameter] ?? '',
      );

  static String? _requireAdminFormArgs(
    BuildContext context,
    GoRouterState state,
  ) =>
      state.extra is AdminFormArgs ? null : AppRoutes.adminAdmins;

  static int? _familyGroupIdOf(GoRouterState state) => int.tryParse(
        state.pathParameters[AppRoutes.familyGroupIdPathParameter] ?? '',
      );

  static String? _requireFamilyGroupId(
    BuildContext context,
    GoRouterState state,
  ) =>
      _familyGroupIdOf(state) == null ? AppRoutes.adminPayments : null;

  static String? _requireMemberId(
    BuildContext context,
    GoRouterState state,
  ) =>
      _memberIdOf(state) == null ? AppRoutes.adminPayments : null;
}
