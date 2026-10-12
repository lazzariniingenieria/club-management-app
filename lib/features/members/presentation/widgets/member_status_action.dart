import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/member.dart';
import '../cubit/member_form_cubit.dart';

class MemberStatusAction extends StatelessWidget {
  final Member member;

  const MemberStatusAction({super.key, required this.member});

  Future<void> _confirmAndApply(BuildContext context) async {
    final cubit = context.read<MemberFormCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _StatusConfirmationDialog(member: member),
    );

    if (confirmed ?? false) {
      await cubit.setActive(member.id, isActive: !member.isActive);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = member.isActive;

    return OutlinedButton.icon(
      onPressed: () => _confirmAndApply(context),
      icon: Icon(
        isActive ? Icons.person_off_outlined : Icons.person_add_alt_1_outlined,
      ),
      label: Text(
        isActive
            ? AppStrings.memberDeactivateAction
            : AppStrings.memberReactivateAction,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor:
            isActive ? AppColors.dangerText : AppColors.successText,
        side: BorderSide(
          color: isActive ? AppColors.dangerSurface : AppColors.successSurface,
        ),
      ),
    );
  }
}

class _StatusConfirmationDialog extends StatelessWidget {
  final Member member;

  const _StatusConfirmationDialog({required this.member});

  @override
  Widget build(BuildContext context) {
    final isActive = member.isActive;

    return AlertDialog(
      title: Text(
        isActive
            ? AppStrings.memberDeactivateConfirmTitle(member.fullName)
            : AppStrings.memberReactivateConfirmTitle(member.fullName),
      ),
      content: Text(
        isActive
            ? AppStrings.memberDeactivateConfirmMessage
            : AppStrings.memberReactivateConfirmMessage,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor:
                isActive ? AppColors.dangerText : AppColors.successText,
          ),
          child: Text(
            isActive
                ? AppStrings.memberDeactivateAction
                : AppStrings.memberReactivateAction,
          ),
        ),
      ],
    );
  }
}
