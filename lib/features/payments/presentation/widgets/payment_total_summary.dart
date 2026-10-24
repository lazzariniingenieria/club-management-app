import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/formatters/display_formats.dart';
import '../cubit/payment_form.dart';

class PaymentTotalSummary extends StatelessWidget {
  final PaymentForm form;

  const PaymentTotalSummary({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.infoSurface,
          borderRadius: AppRadius.mdAll,
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              AppStrings.registerPaymentAmountTimesMonths(
                AppStrings.monthCount(form.selectedMonths.length),
                DisplayFormats.pesos(form.amountCents ?? 0),
              ),
              style: AppTextStyles.bodyLarge,
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${AppStrings.registerPaymentTotalLabel} ',
                    style: AppTextStyles.labelLarge,
                  ),
                  TextSpan(
                    text: DisplayFormats.pesos(form.totalCents),
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
