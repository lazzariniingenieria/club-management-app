import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum AppPillTone { danger, success, neutral, highlight }

class AppPill extends StatelessWidget {
  final String label;
  final AppPillTone tone;

  const AppPill({super.key, required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colorsOf(tone);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: AppTextStyles.badgeLabel.copyWith(color: foreground),
      ),
    );
  }

  static (Color, Color) _colorsOf(AppPillTone tone) {
    return switch (tone) {
      AppPillTone.danger => (AppColors.dangerSurface, AppColors.dangerText),
      AppPillTone.success => (
          AppColors.successSurface,
          AppColors.successText
        ),
      AppPillTone.neutral => (
          AppColors.disabledSurface,
          AppColors.textSecondary
        ),
      AppPillTone.highlight => (AppColors.accentBlue, AppColors.textOnDark),
    };
  }
}
