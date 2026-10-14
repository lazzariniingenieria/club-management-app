import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

enum QuickAccessVariant { newMember, registerPayment }

class QuickAccessCard extends StatelessWidget {
  final String label;
  final QuickAccessVariant variant;
  final VoidCallback onTap;
  final bool isEnabled;

  const QuickAccessCard({
    super.key,
    required this.label,
    required this.variant,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = _QuickAccessStyle.of(variant, isEnabled: isEnabled);

    return Semantics(
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      label: label,
      child: Material(
        color: style.background,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: style.border,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: _QuickAccessContent(label: label, style: style),
        ),
      ),
    );
  }
}

class _QuickAccessContent extends StatelessWidget {
  final String label;
  final _QuickAccessStyle style;

  const _QuickAccessContent({required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, color: style.foreground),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(color: style.foreground),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessStyle {
  final Color background;
  final Color foreground;
  final BorderSide border;
  final IconData icon;

  const _QuickAccessStyle({
    required this.background,
    required this.icon,
    this.foreground = AppColors.textOnDark,
    this.border = BorderSide.none,
  });

  static _QuickAccessStyle of(
    QuickAccessVariant variant, {
    required bool isEnabled,
  }) {
    final icon = _iconOf(variant);
    if (!isEnabled) {
      return _QuickAccessStyle(
        background: AppColors.disabledSurface,
        foreground: AppColors.textSecondary,
        border: const BorderSide(color: AppColors.textSecondary),
        icon: icon,
      );
    }

    return _QuickAccessStyle(background: _backgroundOf(variant), icon: icon);
  }

  static IconData _iconOf(QuickAccessVariant variant) {
    return switch (variant) {
      QuickAccessVariant.newMember => Icons.person_add_alt_1_rounded,
      QuickAccessVariant.registerPayment => Icons.payments_outlined,
    };
  }

  static Color _backgroundOf(QuickAccessVariant variant) {
    return switch (variant) {
      QuickAccessVariant.newMember => AppColors.brandNavy,
      QuickAccessVariant.registerPayment => AppColors.brandGreen,
    };
  }
}
