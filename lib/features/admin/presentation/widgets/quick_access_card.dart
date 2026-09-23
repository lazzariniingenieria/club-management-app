import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

enum QuickAccessVariant { members, courts }

class QuickAccessCard extends StatelessWidget {
  final String label;
  final QuickAccessVariant variant;
  final VoidCallback onTap;

  const QuickAccessCard({
    super.key,
    required this.label,
    required this.variant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _QuickAccessStyle.of(variant);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: label,
      child: Material(
        color: style.background,
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(style.icon, color: AppColors.textOnDark),
                const SizedBox(height: AppSpacing.md),
                Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textOnDark,
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

class _QuickAccessStyle {
  final Color background;
  final IconData icon;

  const _QuickAccessStyle({required this.background, required this.icon});

  static _QuickAccessStyle of(QuickAccessVariant variant) {
    return switch (variant) {
      QuickAccessVariant.members => const _QuickAccessStyle(
          background: AppColors.brandNavy,
          icon: Icons.groups_rounded,
        ),
      QuickAccessVariant.courts => const _QuickAccessStyle(
          background: AppColors.brandGreen,
          icon: Icons.sports_tennis_rounded,
        ),
    };
  }
}
