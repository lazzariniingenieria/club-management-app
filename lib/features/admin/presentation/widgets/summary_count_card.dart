import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

enum SummaryCardVariant { activeMembers, overdueMembers }

class SummaryCountCard extends StatelessWidget {
  final String label;
  final int count;
  final SummaryCardVariant variant;
  final VoidCallback onTap;

  const SummaryCountCard({
    super.key,
    required this.label,
    required this.count,
    required this.variant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _SummaryCardStyle.of(variant);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '$label: $count',
      child: Material(
        color: style.background,
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(style.icon, color: style.countColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: AppTextStyles.sectionLabel.copyWith(
                      color: style.labelColor,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: style.countColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCardStyle {
  final Color background;
  final Color labelColor;
  final Color countColor;
  final IconData icon;

  const _SummaryCardStyle({
    required this.background,
    required this.labelColor,
    required this.countColor,
    required this.icon,
  });

  static _SummaryCardStyle of(SummaryCardVariant variant) {
    return switch (variant) {
      SummaryCardVariant.activeMembers => const _SummaryCardStyle(
          background: AppColors.brandNavy,
          labelColor: AppColors.infoSurface,
          countColor: AppColors.textOnDark,
          icon: Icons.groups_rounded,
        ),
      SummaryCardVariant.overdueMembers => const _SummaryCardStyle(
          background: AppColors.infoSurface,
          labelColor: AppColors.brandNavy,
          countColor: AppColors.dangerText,
          icon: Icons.error_outline_rounded,
        ),
    };
  }
}
