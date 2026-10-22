import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

enum PaymentNoticeTone { info, danger }

class PaymentNotice extends StatelessWidget {
  final String message;
  final String? title;
  final PaymentNoticeTone tone;
  final Widget? action;

  const PaymentNotice({
    super.key,
    required this.message,
    this.title,
    this.tone = PaymentNoticeTone.info,
    this.action,
  });

  bool get _isDanger => tone == PaymentNoticeTone.danger;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: _isDanger,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: _isDanger ? AppColors.dangerSurface : AppColors.infoSurface,
          borderRadius: AppRadius.mdAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NoticeText(title: title, message: message, isDanger: _isDanger),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.sm),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _NoticeText extends StatelessWidget {
  final String? title;
  final String message;
  final bool isDanger;

  const _NoticeText({
    required this.title,
    required this.message,
    required this.isDanger,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDanger ? AppColors.dangerText : AppColors.textPrimary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isDanger ? Icons.error_outline_rounded : Icons.info_outline_rounded,
          color: accent,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (title != null)
                  TextSpan(
                    text: '$title ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                TextSpan(text: message),
              ],
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
