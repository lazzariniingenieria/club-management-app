import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../members/domain/entities/member.dart';
import '../cubit/family_group_name_cubit.dart';
import '../formatting/family_group_formats.dart';

class FamilyGroupCard extends StatelessWidget {
  final Member member;
  final List<Member> relatives;
  final VoidCallback onBuild;
  final ValueChanged<int> onOpen;

  const FamilyGroupCard({
    super.key,
    required this.member,
    required this.relatives,
    required this.onBuild,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final familyGroupId = member.familyGroupId;
    if (familyGroupId == null) return _NoGroupCard(onBuild: onBuild);

    return BlocProvider<FamilyGroupNameCubit>(
      key: ValueKey(familyGroupId),
      create: (_) => sl<FamilyGroupNameCubit>()..load(familyGroupId),
      child: _GroupCard(
        relatives: relatives,
        onOpen: () => onOpen(familyGroupId),
      ),
    );
  }
}

class _CardFrame extends StatelessWidget {
  final Widget child;

  const _CardFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _GroupIcon extends StatelessWidget {
  const _GroupIcon();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.infoSurface,
      child: Icon(Icons.groups_outlined, color: AppColors.textPrimary),
    );
  }
}

class _NoGroupCard extends StatelessWidget {
  final VoidCallback onBuild;

  const _NoGroupCard({required this.onBuild});

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MergeSemantics(
              child: _CardHeading(
                title: AppStrings.familyGroupNone,
                subtitle: AppStrings.familyGroupNoneHint,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSecondaryButton(
              label: AppStrings.familyGroupBuildAction,
              onPressed: onBuild,
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final List<Member> relatives;
  final VoidCallback onOpen;

  const _GroupCard({required this.relatives, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Semantics(
            button: true,
            hint: AppStrings.familyGroupOpenHint,
            child: BlocBuilder<FamilyGroupNameCubit, FamilyGroupNameState>(
              builder: (context, state) => _GroupCardContent(
                name: state.isLoading
                    ? null
                    : FamilyGroupFormats.displayName(state.group),
                relatives: FamilyGroupFormats.relatives(relatives),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupCardContent extends StatelessWidget {
  final String? name;
  final String relatives;

  const _GroupCardContent({required this.name, required this.relatives});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: name == null
                ? const _LoadingHeading()
                : _CardHeading(title: name!, subtitle: relatives),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _CardHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CardHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GroupIcon(),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.familyGroupSectionLabel.toUpperCase(),
                style: AppTextStyles.sectionLabel,
              ),
              Text(title, style: AppTextStyles.labelLarge),
              Text(subtitle, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingHeading extends StatelessWidget {
  const _LoadingHeading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _GroupIcon(),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 14, width: 120),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(height: 16, width: 180),
            ],
          ),
        ),
      ],
    );
  }
}
