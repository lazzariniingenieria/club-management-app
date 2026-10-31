import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/payment_method.dart';
import '../formatting/payment_formats.dart';

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;

  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final method in PaymentMethod.values)
          ChoiceChip(
            label: Text(PaymentFormats.method(method)),
            selected: method == selected,
            showCheckmark: true,
            checkmarkColor: AppColors.textOnDark,
            labelStyle: TextStyle(
              color: method == selected
                  ? AppColors.textOnDark
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
              color: method == selected
                  ? AppColors.brandNavy
                  : AppColors.textSecondary,
            ),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            onSelected: (_) => onSelected(method),
          ),
      ],
    );
  }
}
