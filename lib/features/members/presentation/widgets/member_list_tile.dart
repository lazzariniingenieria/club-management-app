import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/member.dart';
import 'member_status_badge.dart';

class MemberListTile extends StatelessWidget {
  final Member member;
  final bool isSelectedForReport;
  final VoidCallback onEdit;
  final VoidCallback onToggleReport;

  const MemberListTile({
    super.key,
    required this.member,
    required this.isSelectedForReport,
    required this.onEdit,
    required this.onToggleReport,
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
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _MemberIdentity(member: member)),
          _EditAction(onPressed: onEdit),
          _ReportAction(
            isSelected: isSelectedForReport,
            onPressed: onToggleReport,
          ),
        ],
      ),
    );
  }
}

class _MemberIdentity extends StatelessWidget {
  final Member member;

  const _MemberIdentity({required this.member});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(member.fullName, style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          MemberStatusBadge(status: member.status),
        ],
      ),
    );
  }
}

class _EditAction extends StatelessWidget {
  final VoidCallback onPressed;

  const _EditAction({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: AppStrings.memberEditAction,
      icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
    );
  }
}

class _ReportAction extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onPressed;

  const _ReportAction({required this.isSelected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: isSelected
          ? AppStrings.memberRemoveFromReportAction
          : AppStrings.memberAddToReportAction,
      icon: Icon(
        isSelected ? Icons.description_rounded : Icons.description_outlined,
        color: isSelected ? AppColors.accentBlue : AppColors.brandNavy,
      ),
    );
  }
}
