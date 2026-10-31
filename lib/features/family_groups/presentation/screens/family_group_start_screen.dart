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
import '../../../../shared/formatters/display_formats.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/status_message_view.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../members/domain/entities/homonyms.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/presentation/widgets/member_search_field.dart';
import '../cubit/family_group_picker_cubit.dart';
import '../cubit/family_group_picker_state.dart';

class FamilyGroupStartScreen extends StatelessWidget {
  const FamilyGroupStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FamilyGroupPickerCubit>(
      create: (_) => sl<FamilyGroupPickerCubit>()..load(),
      child: AdminScaffold(
        title: AppStrings.familyGroupPickerBuildTitle,
        body: BlocBuilder<FamilyGroupPickerCubit, FamilyGroupPickerState>(
          builder: (context, state) => switch (state) {
            FamilyGroupPickerLoading() => const _StartSkeleton(),
            FamilyGroupPickerFailure(:final isOffline) => StatusMessageView(
                icon: isOffline ? Icons.wifi_off_rounded : Icons.dns_outlined,
                title: AppStrings.familyGroupPickerErrorTitle,
                message: isOffline
                    ? AppStrings.networkErrorMessage
                    : AppStrings.familyGroupServerMessage,
                actionLabel: AppStrings.retryAction,
                onAction: context.read<FamilyGroupPickerCubit>().load,
              ),
            FamilyGroupPickerReady() => _StartContent(state: state),
          },
        ),
      ),
    );
  }
}

class _StartContent extends StatelessWidget {
  final FamilyGroupPickerReady state;

  const _StartContent({required this.state});

  List<Member> get _withoutGroup => state.candidates.roster
      .where((member) => member.isActive && member.familyGroupId == null)
      .toList()
    ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

  @override
  Widget build(BuildContext context) {
    final candidates = _withoutGroup;
    final visible =
        candidates.where((member) => member.matches(state.searchQuery)).toList();
    final homonyms = Homonyms.among(candidates);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(child: _StartIntro(query: state.searchQuery)),
              if (visible.isEmpty)
                SliverToBoxAdapter(
                  child: _StartEmpty(hasSearchQuery: state.hasSearchQuery),
                ),
              SliverList.separated(
                itemCount: visible.length,
                itemBuilder: (_, index) => _StartMemberTile(
                  member: visible[index],
                  showsDni: homonyms.includes(visible[index]),
                ),
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StartIntro extends StatelessWidget {
  final String query;

  const _StartIntro({required this.query});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.familyGroupStartQuestion,
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        MemberSearchField(
          query: query,
          onChanged: context.read<FamilyGroupPickerCubit>().search,
          hintText: AppStrings.paymentPickerSearchHint,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _StartEmpty extends StatelessWidget {
  final bool hasSearchQuery;

  const _StartEmpty({required this.hasSearchQuery});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Text(
        hasSearchQuery
            ? AppStrings.adminMembersEmptySearch
            : AppStrings.familyGroupStartNoCandidates,
        style: AppTextStyles.bodyLargeMuted,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _StartMemberTile extends StatelessWidget {
  final Member member;
  final bool showsDni;

  const _StartMemberTile({required this.member, required this.showsDni});

  Future<void> _pick(BuildContext context) async {
    final message = await context.push<String>(
      AppRoutes.adminFamilyGroupCreation(member.id),
    );
    if (message != null && context.mounted) context.pop(message);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: AppRadius.mdAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: _StartMemberIdentity(member: member, showsDni: showsDni),
          ),
        ),
      ),
    );
  }
}

class _StartMemberIdentity extends StatelessWidget {
  final Member member;
  final bool showsDni;

  const _StartMemberIdentity({required this.member, required this.showsDni});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(member.fullName, style: AppTextStyles.labelLarge),
          if (showsDni)
            Text(
              AppStrings.memberDni(DisplayFormats.dni(member.dni)),
              style: AppTextStyles.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class _StartSkeleton extends StatelessWidget {
  const _StartSkeleton();

  static const int _placeholderRows = 6;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SkeletonBox(height: 20, width: 220),
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(height: 56),
          const SizedBox(height: AppSpacing.lg),
          for (var row = 0; row < _placeholderRows; row++) ...[
            const SkeletonBox(height: 64),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
