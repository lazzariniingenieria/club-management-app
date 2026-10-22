import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/logout_button.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../admins/presentation/widgets/new_password_sheet.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../payments/presentation/formatting/payment_formats.dart';
import '../cubit/admin_profile_cubit.dart';
import '../cubit/admin_profile_state.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/monthly_fee_sheet.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) => current is AuthAuthenticated,
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox.shrink();

        return BlocProvider<AdminProfileCubit>(
          create: (_) =>
              sl<AdminProfileCubit>()..load(memberId: state.user.memberId),
          child: AdminScaffold(
            title: AppStrings.adminProfileTitle,
            showsRoleBadge: true,
            body: _ProfileBody(user: state.user),
          ),
        );
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final User user;

  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminProfileCubit, AdminProfileState>(
      builder: (context, state) => RefreshIndicator(
        onRefresh: context.read<AdminProfileCubit>().reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const _SectionTitle(AppStrings.profileAccountSection),
            _AccountCard(user: user, state: state),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle(AppStrings.profileClubSection),
            _ClubCard(user: user, state: state),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle(AppStrings.profileSecuritySection),
            _SecurityActions(user: user),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(title.toUpperCase(), style: AppTextStyles.sectionLabel),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Widget child;

  const _ProfileCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _AccountCard extends StatelessWidget {
  final User user;
  final AdminProfileState state;

  const _AccountCard({required this.user, required this.state});

  @override
  Widget build(BuildContext context) {
    return _ProfileCard(
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.role == UserRole.superAdmin
                  ? AppStrings.profileRoleSuperAdmin
                  : AppStrings.profileRoleAdmin,
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            _linkedMember(),
          ],
        ),
      ),
    );
  }

  Widget _linkedMember() {
    if (user.memberId == null) {
      return Text(AppStrings.profileNotLinked, style: AppTextStyles.bodyMedium);
    }
    if (state.isLoadingMember) return const SkeletonBox(height: 16, width: 200);

    final member = state.linkedMember;
    if (member == null) return const SizedBox.shrink();

    return Text(
      '${AppStrings.profileLinkedMember(member.fullName)} · '
      '${AppStrings.memberDni(PaymentFormats.dni(member.dni))}',
      style: AppTextStyles.bodyMedium,
    );
  }
}

class _ClubCard extends StatelessWidget {
  final User user;
  final AdminProfileState state;

  const _ClubCard({required this.user, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.clubStatus == ProfileClubStatus.loading) {
      return const SkeletonBox(height: 132, borderRadius: AppRadius.lgAll);
    }
    if (state.clubFailed) return _ClubFailure(state: state);

    final club = state.club!;

    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(club.name, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _MonthlyFeeRow(user: user, monthlyFeeCents: club.monthlyFeeCents),
          const SizedBox(height: AppSpacing.sm),
          Text(
            user.role.canEditClubFee
                ? AppStrings.profileMonthlyFeeHelp
                : AppStrings.profileMonthlyFeeReadOnly,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MonthlyFeeRow extends StatelessWidget {
  final User user;
  final int? monthlyFeeCents;

  const _MonthlyFeeRow({required this.user, required this.monthlyFeeCents});

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<AdminProfileCubit>();
    final saved = await MonthlyFeeSheet.show(
      context,
      MonthlyFeeSheet(
        initialCents: monthlyFeeCents,
        onSave: cubit.updateMonthlyFee,
      ),
    );
    if (saved && context.mounted) showAppSnackBar(context, AppStrings.feeSaved);
  }

  @override
  Widget build(BuildContext context) {
    final fee = monthlyFeeCents;

    return Row(
      children: [
        Expanded(
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.profileMonthlyFeeLabel,
                  style: AppTextStyles.bodyMedium,
                ),
                Text(
                  fee == null
                      ? AppStrings.profileMonthlyFeeUnset
                      : PaymentFormats.pesos(fee),
                  style: AppTextStyles.labelLarge,
                ),
              ],
            ),
          ),
        ),
        if (user.role.canEditClubFee)
          IconButton(
            onPressed: () => _edit(context),
            tooltip: AppStrings.profileEditMonthlyFee,
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
          ),
      ],
    );
  }
}

class _ClubFailure extends StatelessWidget {
  final AdminProfileState state;

  const _ClubFailure({required this.state});

  @override
  Widget build(BuildContext context) {
    return AppNotice(
      tone: AppNoticeTone.danger,
      message: state.clubStatus == ProfileClubStatus.offline
          ? AppStrings.profileClubOffline
          : AppStrings.profileClubFailed,
      action: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: context.read<AdminProfileCubit>().reload,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text(AppStrings.retryAction),
        ),
      ),
    );
  }
}

class _SecurityActions extends StatelessWidget {
  final User user;

  const _SecurityActions({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileAction(
          icon: Icons.lock_reset_rounded,
          label: AppStrings.profileChangePassword,
          onTap: () => _changePassword(context),
        ),
        if (user.role.canManageAdmins) ...[
          const SizedBox(height: AppSpacing.sm),
          _ProfileAction(
            icon: Icons.admin_panel_settings_outlined,
            label: AppStrings.adminProfileManageAdmins,
            onTap: () => context.push(AppRoutes.adminAdmins),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        const LogoutButton(),
      ],
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    if (!user.role.canChangeOwnPassword) {
      showAppSnackBar(context, AppStrings.profileChangePasswordUnavailable);
      return;
    }

    final cubit = context.read<AdminProfileCubit>();
    final changed = await NewPasswordSheet.show(
      context,
      NewPasswordSheet(
        title: AppStrings.passwordSheetTitle,
        notice: AppStrings.passwordChangeNotice,
        actionLabel: AppStrings.passwordChangeAction,
        onSave: (password) => cubit.changePassword(user.id, password),
      ),
    );
    if (changed && context.mounted) await _signInAgain(context);
  }

  Future<void> _signInAgain(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.passwordChangedTitle),
        content: const Text(AppStrings.passwordChangedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.passwordChangedAction),
          ),
        ],
      ),
    );
    authBloc.add(const AuthLogoutRequested());
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: AppColors.textPrimary),
        title: Text(label, style: AppTextStyles.labelLarge),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
