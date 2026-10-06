import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/member.dart';

class MemberStatusBadge extends StatelessWidget {
  final MemberStatus status;

  const MemberStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final style = _MemberStatusStyle.of(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        style.label,
        style: AppTextStyles.badgeLabel.copyWith(color: style.labelColor),
      ),
    );
  }
}

class _MemberStatusStyle {
  final String label;
  final Color background;
  final Color labelColor;

  const _MemberStatusStyle({
    required this.label,
    required this.background,
    required this.labelColor,
  });

  static _MemberStatusStyle of(MemberStatus status) {
    return switch (status) {
      MemberStatus.active => const _MemberStatusStyle(
          label: AppStrings.memberStatusActive,
          background: AppColors.successSurface,
          labelColor: AppColors.successText,
        ),
      MemberStatus.inactive => const _MemberStatusStyle(
          label: AppStrings.memberStatusInactive,
          background: AppColors.disabledSurface,
          labelColor: AppColors.textSecondary,
        ),
    };
  }
}
