import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/admin.dart';
import '../cubit/admin_form_cubit.dart';
import '../formatting/admin_formats.dart';
import 'new_password_sheet.dart';

class AdminAccountActions extends StatelessWidget {
  final Admin admin;
  final List<Member> members;

  const AdminAccountActions({
    super.key,
    required this.admin,
    required this.members,
  });

  String get _name {
    Member? linked;
    for (final member in members) {
      if (member.id == admin.memberId) linked = member;
    }

    return AdminFormats.displayName(admin, linked);
  }

  Future<void> _resetPassword(BuildContext context) async {
    final cubit = context.read<AdminFormCubit>();
    final reset = await NewPasswordSheet.show(
      context,
      NewPasswordSheet(
        title: AppStrings.adminResetPassword,
        notice: AppStrings.adminResetPasswordNotice,
        actionLabel: AppStrings.adminResetPassword,
        onSave: (password) => cubit.resetPassword(admin.id, password),
      ),
    );
    if (reset && context.mounted) {
      showAppSnackBar(context, AppStrings.adminResetPasswordDone);
    }
  }

  Future<void> _toggleActive(BuildContext context) async {
    final cubit = context.read<AdminFormCubit>();
    final deactivating = admin.isActive;
    final confirmed = await ConfirmationDialog.show(
      context,
      ConfirmationDialog(
        title: deactivating
            ? AppStrings.adminDeactivateTitle(_name)
            : AppStrings.adminReactivateTitle(_name),
        message: deactivating
            ? AppStrings.adminDeactivateMessage
            : AppStrings.adminReactivateMessage,
        confirmLabel: deactivating
            ? AppStrings.adminDeactivate
            : AppStrings.adminReactivateShort,
        isDestructive: deactivating,
      ),
    );
    if (confirmed) await cubit.setActive(admin.id, isActive: !deactivating);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSecondaryButton(
          label: AppStrings.adminResetPassword,
          onPressed: () => _resetPassword(context),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => _toggleActive(context),
          icon: Icon(
            admin.isActive
                ? Icons.person_off_outlined
                : Icons.person_outline_rounded,
          ),
          label: Text(
            admin.isActive
                ? AppStrings.adminDeactivate
                : AppStrings.adminReactivate,
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor:
                admin.isActive ? AppColors.dangerText : AppColors.successText,
          ),
        ),
      ],
    );
  }
}
