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
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/error_retry_view.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/member_collection_filter.dart';
import '../cubit/admin_payments_cubit.dart';
import '../cubit/admin_payments_state.dart';
import '../widgets/member_filter_chips.dart';
import '../widgets/member_list_tile.dart';
import '../widgets/member_search_field.dart';

class AdminPaymentsScreen extends StatelessWidget {
  final MemberCollectionFilter filter;

  const AdminPaymentsScreen({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminPaymentsCubit>(
      create: (_) => sl<AdminPaymentsCubit>()..load(),
      child: AdminScaffold(
        title: AppStrings.adminPaymentsTitle,
        floatingActionButton: _CreateMemberButton(filter: filter),
        body: _AdminPaymentsBody(filter: filter),
      ),
    );
  }
}

class _AdminPaymentsBody extends StatelessWidget {
  final MemberCollectionFilter filter;

  const _AdminPaymentsBody({required this.filter});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminPaymentsCubit, AdminPaymentsState>(
      listenWhen: (previous, current) =>
          current is AdminPaymentsFailure && current.previous != null,
      listener: (context, state) {
        if (state is AdminPaymentsFailure) {
          showAppSnackBar(context, state.message);
        }
      },
      builder: (context, state) => switch (state) {
        AdminPaymentsLoading() => const _RosterSkeleton(),
        AdminPaymentsReady() => _RosterContent(state: state, filter: filter),
        AdminPaymentsFailure(previous: final roster?) =>
          _RosterContent(state: roster, filter: filter),
        AdminPaymentsFailure(:final message) => _RosterError(message: message),
      },
    );
  }
}

class _RosterContent extends StatelessWidget {
  final AdminPaymentsReady state;
  final MemberCollectionFilter filter;

  const _RosterContent({required this.state, required this.filter});

  bool get _showsReportBar => reportBarIsVisible(state, filter);

  @override
  Widget build(BuildContext context) {
    final members = state.visibleMembers(filter);

    return Column(
      children: [
        _RosterHeader(state: state, filter: filter),
        Expanded(
          child: members.isEmpty
              ? _RosterEmpty(state: state, filter: filter)
              : _MemberList(state: state, members: members),
        ),
        if (_showsReportBar)
          _GenerateReportBar(count: state.selectedMemberIds.length),
      ],
    );
  }
}

class _RosterHeader extends StatelessWidget {
  final AdminPaymentsReady state;
  final MemberCollectionFilter filter;

  const _RosterHeader({required this.state, required this.filter});

  void _openFilter(BuildContext context, MemberCollectionFilter next) =>
      context.go(AppRoutes.adminPaymentsWithFilter(next.queryValue));

  Map<MemberCollectionFilter, int> get _counts => {
        for (final value in MemberCollectionFilter.values)
          value: state.countFor(value),
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: MemberSearchField(
            query: state.searchQuery,
            onChanged: context.read<AdminPaymentsCubit>().search,
          ),
        ),
        MemberFilterChips(
          selected: filter,
          counts: _counts,
          onSelected: (next) => _openFilter(context, next),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _MemberList extends StatelessWidget {
  final AdminPaymentsReady state;
  final List<Member> members;

  const _MemberList({required this.state, required this.members});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<AdminPaymentsCubit>().load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          _floatingActionClearance,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => _tileFor(context, members[index]),
      ),
    );
  }

  Widget _tileFor(BuildContext context, Member member) {
    return MemberListTile(
      member: member,
      isSelectedForReport: state.isSelected(member),
      onEdit: () => showAppSnackBar(context, AppStrings.comingSoonEditMember),
      onToggleReport: () =>
          context.read<AdminPaymentsCubit>().toggleReportSelection(member.id),
    );
  }
}

class _RosterEmpty extends StatelessWidget {
  final AdminPaymentsReady state;
  final MemberCollectionFilter filter;

  const _RosterEmpty({required this.state, required this.filter});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<AdminPaymentsCubit>().load,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: _EmptyMessage(state: state, filter: filter),
          ),
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final AdminPaymentsReady state;
  final MemberCollectionFilter filter;

  const _EmptyMessage({required this.state, required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.groups_outlined,
              size: 48,
              color: AppColors.disabledText,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _emptyMessageFor(state, filter),
              style: AppTextStyles.bodyLargeMuted,
              textAlign: TextAlign.center,
            ),
            if (state.hasSearchQuery) const _ClearSearchAction(),
          ],
        ),
      ),
    );
  }
}

class _ClearSearchAction extends StatelessWidget {
  const _ClearSearchAction();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: TextButton(
        onPressed: context.read<AdminPaymentsCubit>().clearSearch,
        child: const Text(AppStrings.adminPaymentsClearSearch),
      ),
    );
  }
}

class _GenerateReportBar extends StatelessWidget {
  final int count;

  const _GenerateReportBar({required this.count});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ElevatedButton(
            onPressed: () => showAppSnackBar(
              context,
              AppStrings.comingSoonGenerateReport,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.disabledSurface,
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text(
              AppStrings.withCount(
                AppStrings.adminPaymentsGenerateReport,
                count,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateMemberButton extends StatelessWidget {
  final MemberCollectionFilter filter;

  const _CreateMemberButton({required this.filter});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminPaymentsCubit, AdminPaymentsState>(
      builder: (context, state) => _yieldsToReportBar(state)
          ? const SizedBox.shrink()
          : _button(context),
    );
  }

  bool _yieldsToReportBar(AdminPaymentsState state) {
    return state is AdminPaymentsReady && reportBarIsVisible(state, filter);
  }

  Widget _button(BuildContext context) {
    return FloatingActionButton(
      onPressed: () =>
          showAppSnackBar(context, AppStrings.comingSoonCreateMember),
      backgroundColor: AppColors.disabledSurface,
      foregroundColor: AppColors.textSecondary,
      elevation: 0,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.textSecondary, width: 1.5),
      ),
      tooltip: AppStrings.adminPaymentsCreateMember,
      child: const Icon(Icons.add_rounded),
    );
  }
}

class _RosterError extends StatelessWidget {
  final String message;

  const _RosterError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ErrorRetryView(
        title: AppStrings.adminPaymentsErrorTitle,
        message: message,
        onRetry: context.read<AdminPaymentsCubit>().load,
      ),
    );
  }
}

class _RosterSkeleton extends StatelessWidget {
  const _RosterSkeleton();

  static const int _placeholderRows = 7;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SkeletonBox(height: 56),
          const SizedBox(height: AppSpacing.md),
          const _SkeletonBox(height: 36, width: 220),
          const SizedBox(height: AppSpacing.lg),
          for (var row = 0; row < _placeholderRows; row++) ...[
            const _SkeletonBox(height: 72),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;

  const _SkeletonBox({required this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.disabledSurface,
          borderRadius: AppRadius.mdAll,
        ),
      ),
    );
  }
}

const double _floatingActionClearance = 88;

bool reportBarIsVisible(
  AdminPaymentsReady state,
  MemberCollectionFilter filter,
) {
  return filter == MemberCollectionFilter.toCollect &&
      state.selectedMemberIds.isNotEmpty;
}

String _emptyMessageFor(
  AdminPaymentsReady state,
  MemberCollectionFilter filter,
) {
  if (state.hasSearchQuery) return AppStrings.adminPaymentsEmptySearch;

  return switch (filter) {
    MemberCollectionFilter.all => AppStrings.adminPaymentsEmptyRoster,
    MemberCollectionFilter.overdue => AppStrings.adminPaymentsEmptyOverdue,
    MemberCollectionFilter.toCollect => AppStrings.adminPaymentsEmptyToCollect,
  };
}
