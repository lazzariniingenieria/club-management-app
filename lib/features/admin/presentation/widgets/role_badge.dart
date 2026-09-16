import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        _labelFor(role),
        style: AppTextStyles.badgeLabel.copyWith(color: AppColors.successText),
      ),
    );
  }

  static String _labelFor(UserRole role) {
    return switch (role) {
      UserRole.superAdmin => AppStrings.roleBadgeSuperAdmin,
      _ => AppStrings.roleBadgeAdmin,
    };
  }
}
