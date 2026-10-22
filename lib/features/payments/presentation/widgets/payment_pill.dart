import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

enum PaymentPillTone { danger, success, neutral, highlight }

class PaymentPill extends StatelessWidget {
  final String label;
  final PaymentPillTone tone;

  const PaymentPill({super.key, required this.label, required this.tone});

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

  static (Color, Color) _colorsOf(PaymentPillTone tone) {
    return switch (tone) {
      PaymentPillTone.danger => (AppColors.dangerSurface, AppColors.dangerText),
      PaymentPillTone.success => (
          AppColors.successSurface,
          AppColors.successText
        ),
      PaymentPillTone.neutral => (
          AppColors.disabledSurface,
          AppColors.textSecondary
        ),
      PaymentPillTone.highlight => (AppColors.accentBlue, AppColors.textOnDark),
    };
  }
}
