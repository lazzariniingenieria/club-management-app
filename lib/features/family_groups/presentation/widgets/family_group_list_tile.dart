import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../domain/entities/family_group_detail.dart';
import '../formatting/family_group_formats.dart';

class FamilyGroupListTile extends StatelessWidget {
  final FamilyGroupDetail detail;
  final VoidCallback onOpen;

  const FamilyGroupListTile({
    super.key,
    required this.detail,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: AppColors.border),
      ),
      child: Semantics(
        button: true,
        hint: AppStrings.familyGroupOpenHint,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(child: _GroupIdentity(detail: detail)),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupIdentity extends StatelessWidget {
  final FamilyGroupDetail detail;

  const _GroupIdentity({required this.detail});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FamilyGroupFormats.displayName(detail.group),
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail.isEmpty
                ? AppStrings.familyGroupsNoMembers
                : FamilyGroupFormats.namesList(detail.members),
            style: AppTextStyles.bodyMedium,
          ),
          if (detail.hasOverdueMember) ...[
            const SizedBox(height: AppSpacing.sm),
            const AppPill(
              label: AppStrings.memberStatusOverdue,
              tone: AppPillTone.danger,
            ),
          ],
        ],
      ),
    );
  }
}
