import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/inline_error_card.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../family_groups/domain/entities/family_group_detail.dart';
import '../../../family_groups/presentation/widgets/family_group_list_tile.dart';
import '../../../members/presentation/widgets/member_search_field.dart';
import '../cubit/admin_family_groups_cubit.dart';
import '../cubit/admin_family_groups_state.dart';

class FamilyGroupsTab extends StatelessWidget {
  const FamilyGroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminFamilyGroupsCubit, AdminFamilyGroupsState>(
      listenWhen: (_, current) =>
          current is AdminFamilyGroupsFailure && current.previous != null,
      listener: (context, state) {
        if (state is AdminFamilyGroupsFailure) {
          showAppSnackBar(context, state.message, isError: true);
        }
      },
      builder: (context, state) => switch (state) {
        AdminFamilyGroupsLoading() => const _GroupsSkeleton(),
        AdminFamilyGroupsReady() => _GroupsContent(state: state),
        AdminFamilyGroupsFailure(previous: final groups?) =>
          _GroupsContent(state: groups),
        AdminFamilyGroupsFailure(:final message) =>
          _GroupsError(message: message),
      },
    );
  }
}

class _GroupsContent extends StatelessWidget {
  final AdminFamilyGroupsReady state;

  const _GroupsContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final groups = state.visibleGroups;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: MemberSearchField(
            query: state.searchQuery,
            onChanged: context.read<AdminFamilyGroupsCubit>().search,
            hintText: AppStrings.familyGroupsSearchHint,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: context.read<AdminFamilyGroupsCubit>().load,
            child: groups.isEmpty
                ? _GroupsEmpty(hasSearchQuery: state.hasSearchQuery)
                : _GroupList(groups: groups),
          ),
        ),
      ],
    );
  }
}

class _GroupList extends StatelessWidget {
  final List<FamilyGroupDetail> groups;

  const _GroupList({required this.groups});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => FamilyGroupListTile(
        detail: groups[index],
        onOpen: () =>
            context.push(AppRoutes.adminFamilyGroup(groups[index].group.id)),
      ),
    );
  }
}

class _GroupsEmpty extends StatelessWidget {
  final bool hasSearchQuery;

  const _GroupsEmpty({required this.hasSearchQuery});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _EmptyMessage(hasSearchQuery: hasSearchQuery),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final bool hasSearchQuery;

  const _EmptyMessage({required this.hasSearchQuery});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.family_restroom_rounded,
          size: 48,
          color: AppColors.disabledText,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          hasSearchQuery
              ? AppStrings.familyGroupsEmptySearch
              : AppStrings.familyGroupsEmpty,
          style: AppTextStyles.bodyLargeMuted,
          textAlign: TextAlign.center,
        ),
        if (hasSearchQuery)
          TextButton(
            onPressed: context.read<AdminFamilyGroupsCubit>().clearSearch,
            child: const Text(AppStrings.adminMembersClearSearch),
          ),
      ],
    );
  }
}

class _GroupsError extends StatelessWidget {
  final String message;

  const _GroupsError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: InlineErrorCard(
        title: AppStrings.familyGroupsErrorTitle,
        message: message,
        onRetry: context.read<AdminFamilyGroupsCubit>().load,
      ),
    );
  }
}

class _GroupsSkeleton extends StatelessWidget {
  const _GroupsSkeleton();

  static const int _placeholderRows = 6;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SkeletonBox(height: 56),
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
