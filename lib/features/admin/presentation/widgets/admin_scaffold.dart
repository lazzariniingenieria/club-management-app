import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'role_badge.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showsRoleBadge;
  final List<Widget> actions;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.showsRoleBadge = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...actions,
          if (showsRoleBadge) const _CurrentRoleBadge(),
          const SizedBox(width: AppSpacing.lg),
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class _CurrentRoleBadge extends StatelessWidget {
  const _CurrentRoleBadge();

  static const double _maxBadgeTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        final role = state is AuthAuthenticated ? state.user.role : null;
        if (role == null || role == UserRole.member) {
          return const SizedBox.shrink();
        }
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: _maxBadgeTextScale,
          child: RoleBadge(role: role),
        );
      },
    );
  }
}
