import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class StatusMessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isError;

  const StatusMessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.isError = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - AppSpacing.xl * 2)
                .clamp(0, double.infinity),
          ),
          child: Center(child: _message()),
        ),
      ),
    );
  }

  Widget _message() {
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: isError ? AppColors.dangerText : AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTextStyles.bodyLargeMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
