import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/error_retry_view.dart';
import '../../domain/entities/admin_summary.dart';
import '../cubit/admin_home_cubit.dart';
import '../cubit/admin_home_state.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/quick_access_card.dart';
import '../widgets/summary_count_card.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminHomeCubit>(
      create: (_) => sl<AdminHomeCubit>()..load(),
      child: const AdminScaffold(
        title: AppStrings.adminHomeTitle,
        body: _ReloadOnReturn(child: _AdminHomeBody()),
      ),
    );
  }
}

class _ReloadOnReturn extends StatefulWidget {
  final Widget child;

  const _ReloadOnReturn({required this.child});

  @override
  State<_ReloadOnReturn> createState() => _ReloadOnReturnState();
}

class _ReloadOnReturnState extends State<_ReloadOnReturn> {
  GoRouterDelegate? _routerDelegate;
  bool _homeWasShown = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routerDelegate?.removeListener(_onRouteChanged);
    _routerDelegate = GoRouter.maybeOf(context)?.routerDelegate;
    _routerDelegate?.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    _routerDelegate?.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    final homeIsShown = _isShowingHome();
    if (homeIsShown && !_homeWasShown && mounted) {
      context.read<AdminHomeCubit>().load();
    }
    _homeWasShown = homeIsShown;
  }

  bool _isShowingHome() {
    final matches = _routerDelegate!.currentConfiguration;
    return matches.isNotEmpty &&
        matches.last.matchedLocation == AppRoutes.adminHome;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AdminHomeBody extends StatelessWidget {
  const _AdminHomeBody();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<AdminHomeCubit>().load(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          _SectionTitle(AppStrings.adminHomeSummaryTitle),
          SizedBox(height: AppSpacing.md),
          _SummarySection(),
          SizedBox(height: AppSpacing.xl),
          _SectionTitle(AppStrings.adminHomeQuickAccessTitle),
          SizedBox(height: AppSpacing.md),
          _QuickAccessRow(),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(), style: AppTextStyles.sectionLabel);
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminHomeCubit, AdminHomeState>(
      builder: (context, state) => switch (state) {
        AdminHomeLoading() => const _SummarySkeleton(),
        AdminHomeReady(:final summary) => _SummaryCards(summary: summary),
        AdminHomeFailure(:final message) => ErrorRetryView(
            title: AppStrings.adminHomeSummaryErrorTitle,
            message: message,
            onRetry: () => context.read<AdminHomeCubit>().load(),
          ),
      },
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final AdminSummary summary;

  const _SummaryCards({required this.summary});

  void _openMembers(BuildContext context) =>
      context.push(AppRoutes.adminMembers);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SummaryCountCard(
          label: AppStrings.adminHomeActiveMembers,
          count: summary.activeMembers,
          variant: SummaryCardVariant.activeMembers,
          onTap: () => _openMembers(context),
        ),
        const SizedBox(height: AppSpacing.md),
        SummaryCountCard(
          label: AppStrings.adminHomeOverdueMembers,
          count: summary.overdueMembers,
          variant: SummaryCardVariant.overdueMembers,
          onTap: () => _openMembers(context),
        ),
      ],
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SkeletonBox(),
        SizedBox(height: AppSpacing.md),
        _SkeletonBox(),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: const BoxDecoration(
        color: AppColors.disabledSurface,
        borderRadius: AppRadius.lgAll,
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: QuickAccessCard(
              label: AppStrings.adminHomeMembersAccess,
              variant: QuickAccessVariant.members,
              onTap: () => context.push(AppRoutes.adminMembers),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: QuickAccessCard(
              label: AppStrings.adminHomeCourtsAccess,
              variant: QuickAccessVariant.courts,
              onTap: () => context.push(AppRoutes.adminCourts),
            ),
          ),
        ],
      ),
    );
  }
}
