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
import '../../../../shared/widgets/inline_error_card.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/entities/member_collection_filter.dart';
import '../../../members/presentation/widgets/member_filter_chips.dart';
import '../../../members/presentation/widgets/member_list_tile.dart';
import '../../../members/presentation/widgets/member_search_field.dart';
import '../../../payments/presentation/cubit/member_roster_cubit.dart';
import '../../../payments/presentation/cubit/member_roster_state.dart';
import '../cubit/admin_family_groups_cubit.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/family_groups_tab.dart';

class AdminMembersScreen extends StatelessWidget {
  final MemberCollectionFilter filter;
  final bool showsFamilyGroups;

  const AdminMembersScreen({
    super.key,
    required this.filter,
    this.showsFamilyGroups = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MemberRosterCubit>(
          create: (_) => sl<MemberRosterCubit>()..load(),
        ),
        BlocProvider<AdminFamilyGroupsCubit>(
          create: (_) => sl<AdminFamilyGroupsCubit>()..load(),
        ),
      ],
      child: AdminScaffold(
        title: AppStrings.adminMembersTitle,
        showsRoleBadge: true,
        bottom: _MembersTabBar(
          filter: filter,
          showsFamilyGroups: showsFamilyGroups,
        ),
        floatingActionButton: showsFamilyGroups
            ? const _BuildGroupButton()
            : const _CreateMemberButton(),
        body: showsFamilyGroups
            ? const FamilyGroupsTab()
            : _AdminMembersBody(filter: filter),
      ),
    );
  }
}

class _MembersTabBar extends StatefulWidget implements PreferredSizeWidget {
  final MemberCollectionFilter filter;
  final bool showsFamilyGroups;

  const _MembersTabBar({required this.filter, required this.showsFamilyGroups});

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  State<_MembersTabBar> createState() => _MembersTabBarState();
}

class _MembersTabBarState extends State<_MembersTabBar>
    with SingleTickerProviderStateMixin {
  static const int _familyGroupsIndex = 1;

  late final TabController _controller = TabController(
    length: 2,
    vsync: this,
    initialIndex: _indexOf(widget.showsFamilyGroups),
  );
  late MemberCollectionFilter _lastFilter = widget.filter;

  static int _indexOf(bool showsFamilyGroups) =>
      showsFamilyGroups ? _familyGroupsIndex : 0;

  @override
  void didUpdateWidget(_MembersTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showsFamilyGroups) _lastFilter = widget.filter;
    _controller.index = _indexOf(widget.showsFamilyGroups);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(int index) {
    context.go(
      index == _familyGroupsIndex
          ? AppRoutes.adminFamilyGroups
          : AppRoutes.adminMembersWithFilter(_lastFilter),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: _controller,
      onTap: _open,
      labelStyle: AppTextStyles.labelLarge,
      tabs: const [
        Tab(text: AppStrings.adminMembersTabMembers),
        Tab(text: AppStrings.adminMembersTabFamilyGroups),
      ],
    );
  }
}

class _AdminMembersBody extends StatelessWidget {
  final MemberCollectionFilter filter;

  const _AdminMembersBody({required this.filter});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MemberRosterCubit, MemberRosterState>(
      listenWhen: (previous, current) =>
          current is MemberRosterFailure &&
          current.previous != null &&
          current.isNewerThan(previous),
      listener: (context, state) {
        if (state is MemberRosterFailure) {
          showAppSnackBar(context, state.message, isError: true);
        }
      },
      builder: (context, state) => switch (state) {
        MemberRosterLoading() => const _RosterSkeleton(),
        MemberRosterReady() => _RosterContent(state: state, filter: filter),
        MemberRosterFailure(previous: final roster?) =>
          _RosterContent(state: roster, filter: filter),
        MemberRosterFailure(:final message) => _RosterError(message: message),
      },
    );
  }
}

class _RosterContent extends StatelessWidget {
  final MemberRosterReady state;
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
  final MemberRosterReady state;
  final MemberCollectionFilter filter;

  const _RosterHeader({required this.state, required this.filter});

  void _openFilter(BuildContext context, MemberCollectionFilter next) =>
      context.go(AppRoutes.adminMembersWithFilter(next));

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
            onChanged: context.read<MemberRosterCubit>().search,
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
      onRefresh: context.read<MemberRosterCubit>().load,
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
  final MemberRosterReady state;
  final MemberCollectionFilter filter;

  const _RosterEmpty({required this.state, required this.filter});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<MemberRosterCubit>().load,
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
  final MemberRosterReady state;
  final MemberCollectionFilter filter;

  const _EmptyMessage({required this.state, required this.filter});

  int get _inactiveMatches {
    final searchesActiveMembers = filter != MemberCollectionFilter.inactive;
    if (!state.hasSearchQuery || !searchesActiveMembers) return 0;

    return state.visibleMembers(MemberCollectionFilter.inactive).length;
  }

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
            if (_inactiveMatches > 0) _SearchInactiveAction(_inactiveMatches),
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
        onPressed: context.read<MemberRosterCubit>().clearSearch,
        child: const Text(AppStrings.adminMembersClearSearch),
      ),
    );
  }
}

class _SearchInactiveAction extends StatelessWidget {
  final int count;

  const _SearchInactiveAction(this.count);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(
        AppRoutes.adminMembersWithFilter(MemberCollectionFilter.inactive),
      ),
      child: Text(
        AppStrings.withCount(AppStrings.adminMembersSearchInactive, count),
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
      tooltip: AppStrings.adminMembersCreateMember,
      child: const Icon(Icons.add_rounded),
    );
  }
}

class _BuildGroupButton extends StatelessWidget {
  const _BuildGroupButton();

  Future<void> _build(BuildContext context) async {
    final message = await context.push<String>(AppRoutes.adminFamilyGroupStart);
    if (message != null && context.mounted) showAppSnackBar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _build(context),
      backgroundColor: AppColors.accentBlue,
      foregroundColor: AppColors.textOnDark,
      tooltip: AppStrings.familyGroupsBuildAction,
      child: const Icon(Icons.group_add_rounded),
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
      child: InlineErrorCard(
        title: AppStrings.adminMembersErrorTitle,
        message: message,
        onRetry: context.read<MemberRosterCubit>().load,
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
  MemberRosterReady state,
  MemberCollectionFilter filter,
) {
  if (state.hasSearchQuery) return AppStrings.adminMembersEmptySearch;

  return switch (filter) {
    MemberCollectionFilter.all => AppStrings.adminMembersEmptyRoster,
    MemberCollectionFilter.overdue => AppStrings.adminMembersEmptyOverdue,
    MemberCollectionFilter.inactive => AppStrings.adminMembersEmptyInactive,
  };
}
