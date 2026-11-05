import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../domain/entities/member.dart';

class MemberListTile extends StatelessWidget {
  final Member member;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final Widget? tag;

  const MemberListTile({
    super.key,
    required this.member,
    required this.onOpen,
    this.onEdit,
    this.onRemove,
    this.tag,
  }) : assert(onEdit != null || onRemove != null);

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
          Expanded(
            child: _OpenLedgerArea(member: member, onOpen: onOpen, tag: tag),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: onRemove != null
                ? _RemoveAction(member: member, onPressed: onRemove!)
                : _EditAction(onPressed: onEdit!),
          ),
        ],
      ),
    );
  }
}

class _OpenLedgerArea extends StatelessWidget {
  final Member member;
  final VoidCallback onOpen;
  final Widget? tag;

  const _OpenLedgerArea({required this.member, required this.onOpen, this.tag});

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
          child: _MemberIdentity(member: member, tag: tag),
        ),
      ),
    );
  }
}

class _MemberIdentity extends StatelessWidget {
  final Member member;
  final Widget? tag;

  const _MemberIdentity({required this.member, this.tag});

  @override
  Widget build(BuildContext context) {
    final standing = _standingBadgeOf(member);

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(member.fullName, style: AppTextStyles.labelLarge),
              if (tag != null) tag!,
            ],
          ),
          if (standing != null) ...[
            const SizedBox(height: AppSpacing.sm),
            standing,
          ],
        ],
      ),
    );
  }
}

AppPill? _standingBadgeOf(Member member) {
  if (!member.isActive) {
    return const AppPill(
      label: AppStrings.memberStatusInactive,
      tone: AppPillTone.neutral,
    );
  }
  if (member.isOverdue) {
    return const AppPill(
      label: AppStrings.memberStatusOverdue,
      tone: AppPillTone.danger,
    );
  }

  return null;
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

class _RemoveAction extends StatelessWidget {
  final Member member;
  final VoidCallback onPressed;

  const _RemoveAction({required this.member, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.familyGroupRemoveSemantics(member.fullName),
      button: true,
      excludeSemantics: true,
      child: IconButton(
        onPressed: onPressed,
        tooltip: AppStrings.familyGroupRemoveTooltip,
        icon: const Icon(
          Icons.person_remove_outlined,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
