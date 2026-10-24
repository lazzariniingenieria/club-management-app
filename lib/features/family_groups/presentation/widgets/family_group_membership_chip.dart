import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class FamilyGroupMembershipChip extends StatelessWidget {
  final String groupName;

  const FamilyGroupMembershipChip({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.infoSurface,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.group_outlined,
            size: 14,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              AppStrings.familyGroupMembershipChip(groupName),
              style: AppTextStyles.badgeLabel,
            ),
          ),
        ],
      ),
    );
  }
}
