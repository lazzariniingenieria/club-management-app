import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../members/domain/entities/member.dart';

class PayerSelector extends StatelessWidget {
  final Member member;
  final List<Member> relatives;
  final int? selectedPayerId;
  final ValueChanged<int?> onSelected;

  const PayerSelector({
    super.key,
    required this.member,
    required this.relatives,
    required this.selectedPayerId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _PayerOption(
            name: member.fullName,
            note: AppStrings.registerPaymentPayerSelf,
            isSelected: selectedPayerId == null,
            onSelected: () => onSelected(null),
          ),
          for (final relative in relatives)
            _PayerOption(
              name: relative.fullName,
              note: AppStrings.registerPaymentPayerRelative,
              isSelected: selectedPayerId == relative.id,
              onSelected: () => onSelected(relative.id),
            ),
        ],
      ),
    );
  }
}

class _PayerOption extends StatelessWidget {
  final String name;
  final String note;
  final bool isSelected;
  final VoidCallback onSelected;

  const _PayerOption({
    required this.name,
    required this.note,
    required this.isSelected,
    required this.onSelected,
  });

  Color get _radioColor =>
      isSelected ? AppColors.brandNavy : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      button: true,
      label: '$name, $note',
      excludeSemantics: true,
      child: InkWell(
        onTap: onSelected,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: _radioColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: AppTextStyles.bodyLarge),
                    Text(note, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
