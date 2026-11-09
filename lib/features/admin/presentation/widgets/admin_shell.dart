import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/courts_enabled_cubit.dart';

class AdminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShell({super.key, required this.navigationShell});

  static const int reservationsBranch = 2;

  static const List<NavigationDestination> destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: AppStrings.adminTabHome,
    ),
    NavigationDestination(
      icon: Icon(Icons.groups_outlined),
      selectedIcon: Icon(Icons.groups_rounded),
      label: AppStrings.adminTabMembers,
    ),
    NavigationDestination(
      icon: Icon(Icons.event_note_outlined),
      selectedIcon: Icon(Icons.event_note_rounded),
      label: AppStrings.adminTabReservations,
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: AppStrings.adminTabProfile,
    ),
  ];

  static List<int> visibleBranches({required bool courtsEnabled}) => [
        for (var branch = 0; branch < destinations.length; branch++)
          if (courtsEnabled || branch != reservationsBranch) branch,
      ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CourtsEnabledCubit>(
      create: (_) => sl<CourtsEnabledCubit>()..load(),
      child: BlocBuilder<CourtsEnabledCubit, bool>(
        builder: (context, courtsEnabled) => _ShellScaffold(
          navigationShell: navigationShell,
          branches: visibleBranches(courtsEnabled: courtsEnabled),
        ),
      ),
    );
  }
}

class _ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<int> branches;

  const _ShellScaffold({required this.navigationShell, required this.branches});

  static const int _homeBranch = 0;

  int get _selectedDestination {
    final destination = branches.indexOf(navigationShell.currentIndex);

    return destination < 0 ? _homeBranch : destination;
  }

  void _onDestinationSelected(int destination) {
    final branch = branches[destination];
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  bool get _isOnHome => navigationShell.currentIndex == _homeBranch;

  void _returnHomeInsteadOfLeaving(bool didPop, Object? _) {
    if (!didPop) navigationShell.goBranch(_homeBranch);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isOnHome,
      onPopInvokedWithResult: _returnHomeInsteadOfLeaving,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBarTheme(
          data: _navigationBarTheme,
          child: NavigationBar(
            selectedIndex: _selectedDestination,
            onDestinationSelected: _onDestinationSelected,
            destinations: [
              for (final branch in branches) AdminShell.destinations[branch],
            ],
          ),
        ),
      ),
    );
  }

  static final NavigationBarThemeData _navigationBarTheme =
      NavigationBarThemeData(
    backgroundColor: AppColors.brandNavy,
    indicatorColor: AppColors.accentBlue,
    surfaceTintColor: Colors.transparent,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => AppTextStyles.badgeLabel.copyWith(
        color: states.contains(WidgetState.selected)
            ? AppColors.textOnDark
            : AppColors.infoSurface,
      ),
    ),
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? AppColors.textOnDark
            : AppColors.infoSurface,
      ),
    ),
  );
}
