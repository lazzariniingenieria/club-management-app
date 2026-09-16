import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class ComingSoonView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const ComingSoonView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(icon: icon),
            const SizedBox(height: AppSpacing.lg),
            const _ComingSoonPill(),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodyLargeMuted,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;

  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      width: 72,
      decoration: const BoxDecoration(
        color: AppColors.infoSurface,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 32, color: AppColors.brandNavy),
    );
  }
}

class _ComingSoonPill extends StatelessWidget {
  const _ComingSoonPill();

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
        AppStrings.comingSoonBadge.toUpperCase(),
        style: AppTextStyles.badgeLabel.copyWith(color: AppColors.successText),
      ),
    );
  }
}
