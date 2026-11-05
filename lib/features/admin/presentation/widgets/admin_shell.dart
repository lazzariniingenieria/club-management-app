import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShell({super.key, required this.navigationShell});

  static const int _homeIndex = 0;

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
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: AppStrings.adminTabProfile,
    ),
  ];

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  bool get _isOnHome => navigationShell.currentIndex == _homeIndex;

  void _returnHomeInsteadOfLeaving(bool didPop, Object? _) {
    if (!didPop) navigationShell.goBranch(_homeIndex);
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
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: destinations,
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
