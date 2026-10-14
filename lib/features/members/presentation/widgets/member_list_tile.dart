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
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  const MemberListTile({
    super.key,
    required this.member,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _OpenLedgerArea(member: member, onOpen: onOpen)),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _EditAction(onPressed: onEdit),
          ),
        ],
      ),
    );
  }
}

class _OpenLedgerArea extends StatelessWidget {
  final Member member;
  final VoidCallback onOpen;

  const _OpenLedgerArea({required this.member, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      hint: AppStrings.memberOpenLedgerHint,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: _MemberIdentity(member: member),
        ),
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
