import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../members/domain/entities/member.dart';
import '../formatting/payment_formats.dart';

class MemberHeaderCard extends StatelessWidget {
  final Member member;
  final Widget? details;
  final Widget? trailing;

  const MemberHeaderCard({
    super.key,
    required this.member,
    this.details,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _Identity(member: member, details: details)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final Member member;
  final Widget? details;

  const _Identity({required this.member, this.details});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(member.fullName, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.memberDni(PaymentFormats.dni(member.dni)),
            style: AppTextStyles.bodyMedium,
          ),
          if (details != null) ...[
            const SizedBox(height: AppSpacing.sm),
            details!,
          ],
        ],
      ),
    );
  }
}
