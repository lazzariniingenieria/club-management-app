import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../../shared/widgets/logout_button.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/admin_scaffold.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminScaffold(
      title: AppStrings.adminProfileTitle,
      body: ComingSoonView(
        icon: Icons.person_rounded,
        title: AppStrings.adminProfileTitle,
        message: AppStrings.adminProfilePending,
        action: Column(
          children: [
            _ManageAdminsAction(),
            SizedBox(height: AppSpacing.md),
            LogoutButton(),
          ],
        ),
      ),
    );
  }
}

class _ManageAdminsAction extends StatelessWidget {
  const _ManageAdminsAction();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final role = state is AuthAuthenticated ? state.user.role : null;
        if (role == null || !role.canManageAdmins) {
          return const SizedBox.shrink();
        }

        return FilledButton.icon(
          onPressed: () => context.push(AppRoutes.adminAdmins),
          icon: const Icon(Icons.admin_panel_settings_outlined),
          label: const Text(AppStrings.adminProfileManageAdmins),
        );
      },
    );
  }
}
