import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _confirmAndLogout(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const _LogoutConfirmationDialog(),
    );

    if (confirmed ?? false) authBloc.add(const AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirmAndLogout(context),
      icon: const Icon(Icons.logout_rounded),
      label: const Text(AppStrings.logoutAction),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.dangerText,
        side: const BorderSide(color: AppColors.dangerSurface),
      ),
    );
  }
}

class _LogoutConfirmationDialog extends StatelessWidget {
  const _LogoutConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.logoutConfirmTitle),
      content: const Text(AppStrings.logoutConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.dangerText),
          child: const Text(AppStrings.logoutAction),
        ),
      ],
    );
  }
}
