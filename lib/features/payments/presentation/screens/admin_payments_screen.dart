import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/error_retry_view.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/entities/member_collection_filter.dart';
import '../../../members/presentation/widgets/member_filter_chips.dart';
import '../../../members/presentation/widgets/member_list_tile.dart';
import '../../../members/presentation/widgets/member_search_field.dart';
import '../cubit/admin_payments_cubit.dart';
import '../cubit/admin_payments_state.dart';

class AdminPaymentsScreen extends StatelessWidget {
  final MemberCollectionFilter filter;

  const AdminPaymentsScreen({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminPaymentsCubit>(
      create: (_) => sl<AdminPaymentsCubit>()..load(),
      child: AdminScaffold(
        title: AppStrings.adminPaymentsTitle,
        showsRoleBadge: true,
        actions: const [_ReportAction()],
        floatingActionButton: const _CreateMemberButton(),
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
          current is AdminPaymentsFailure &&
          current.previous != null &&
          current.isNewerThan(previous),
      listener: (context, state) {
        if (state is AdminPaymentsFailure) {
          showAppSnackBar(context, state.message, isError: true);
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

  @override
  Widget build(BuildContext context) {
    final members = state.visibleMembers(filter);

    return Column(
      children: [
        _RosterHeader(state: state, filter: filter),
        Expanded(
          child: members.isEmpty
              ? _RosterEmpty(state: state, filter: filter)
              : _MemberList(members: members),
        ),
      ],
    );
  }
}

class _RosterHeader extends StatelessWidget {
  final AdminPaymentsReady state;
  final MemberCollectionFilter filter;

  const _RosterHeader({required this.state, required this.filter});

  void _openFilter(BuildContext context, MemberCollectionFilter next) =>
      context.go(AppRoutes.adminPaymentsWithFilter(next));

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
  final List<Member> members;

  const _MemberList({required this.members});

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
      onOpen: () => context.push(AppRoutes.adminMemberLedger(member.id)),
      onEdit: () => context.push(
        AppRoutes.adminMemberEdition(member.id),
        extra: member,
      ),
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

class _CreateMemberButton extends StatelessWidget {
  const _CreateMemberButton();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.push(AppRoutes.adminMemberCreation),
      backgroundColor: AppColors.accentBlue,
      foregroundColor: AppColors.textOnDark,
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
          const SkeletonBox(height: 56),
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(height: 36, width: 220),
          const SizedBox(height: AppSpacing.lg),
          for (var row = 0; row < _placeholderRows; row++) ...[
            const SkeletonBox(height: 72),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

const double _floatingActionClearance = 88;

String _emptyMessageFor(
  AdminPaymentsReady state,
  MemberCollectionFilter filter,
) {
  if (state.hasSearchQuery) return AppStrings.adminPaymentsEmptySearch;

  return switch (filter) {
    MemberCollectionFilter.all => AppStrings.adminPaymentsEmptyRoster,
    MemberCollectionFilter.overdue => AppStrings.adminPaymentsEmptyOverdue,
  };
}

class _ReportAction extends StatelessWidget {
  const _ReportAction();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push(AppRoutes.adminPaymentReport),
      tooltip: AppStrings.reportTitle,
      icon: const Icon(Icons.picture_as_pdf_outlined),
    );
  }
}
