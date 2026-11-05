import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/status_message_view.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/admin.dart';
import '../../domain/entities/admins_overview.dart';
import '../cubit/admins_cubit.dart';
import '../cubit/admins_state.dart';
import '../formatting/admin_formats.dart';
import 'admin_form_args.dart';

class AdminsScreen extends StatelessWidget {
  const AdminsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminsCubit>(
      create: (_) => sl<AdminsCubit>()..load(),
      child: const AdminScaffold(
        title: AppStrings.adminAdminsTitle,
        floatingActionButton: _NewAdminButton(),
        body: _AdminsBody(),
      ),
    );
  }
}

class _NewAdminButton extends StatelessWidget {
  const _NewAdminButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminsCubit, AdminsState>(
      builder: (context, state) {
        if (state is! AdminsReady) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: () => context.push(
            AppRoutes.adminAdminCreation,
            extra: AdminFormArgs.from(state.overview),
          ),
          icon: const Icon(Icons.person_add_alt_outlined),
          label: const Text(AppStrings.adminsNew),
        );
      },
    );
  }
}

class _AdminsBody extends StatelessWidget {
  const _AdminsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminsCubit, AdminsState>(
      builder: (context, state) => switch (state) {
        AdminsLoading() => const _AdminsSkeleton(),
        AdminsFailure(:final isOffline) => StatusMessageView(
            icon: isOffline ? Icons.wifi_off_rounded : Icons.dns_outlined,
            title: AppStrings.adminsErrorTitle,
            message: isOffline
                ? AppStrings.networkErrorMessage
                : AppStrings.ledgerServerErrorMessage,
            actionLabel: AppStrings.retryAction,
            onAction: context.read<AdminsCubit>().load,
          ),
        AdminsReady(:final overview) => overview.admins.isEmpty
            ? const _EmptyAdmins()
            : _AdminList(overview: overview),
      },
    );
  }
}

class _AdminList extends StatelessWidget {
  final AdminsOverview overview;

  const _AdminList({required this.overview});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<AdminsCubit>().load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          _floatingActionClearance,
        ),
        itemCount: overview.admins.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, index) => _AdminTile(
          admin: overview.admins[index],
          overview: overview,
        ),
      ),
    );
  }
}

const double _floatingActionClearance = 96;

class _AdminTile extends StatelessWidget {
  final Admin admin;
  final AdminsOverview overview;

  const _AdminTile({required this.admin, required this.overview});

  Member? get _member => overview.memberOf(admin);

  void _edit(BuildContext context) {
    context.push(
      AppRoutes.adminAdminEdition(admin.id),
      extra: AdminFormArgs.from(overview, admin: admin),
    );
  }

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
            child: InkWell(
              onTap: () => _edit(context),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _AdminIdentity(admin: admin, member: _member),
              ),
            ),
          ),
          if (!admin.isActive)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _ReactivateAction(admin: admin, member: _member),
            ),
        ],
      ),
    );
  }
}

class _AdminIdentity extends StatelessWidget {
  final Admin admin;
  final Member? member;

  const _AdminIdentity({required this.admin, required this.member});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AdminFormats.displayName(admin, member),
            style: AppTextStyles.labelLarge,
          ),
          Text(_details(), style: AppTextStyles.bodyMedium),
          if (!admin.isActive) ...[
            const SizedBox(height: AppSpacing.sm),
            const AppPill(
              label: AppStrings.memberStatusInactive,
              tone: AppPillTone.neutral,
            ),
          ],
        ],
      ),
    );
  }

  String _details() => admin.email ?? AppStrings.adminRowNoEmail;
}

class _ReactivateAction extends StatelessWidget {
  final Admin admin;
  final Member? member;

  const _ReactivateAction({required this.admin, required this.member});

  Future<void> _reactivate(BuildContext context) async {
    final cubit = context.read<AdminsCubit>();
    final name = AdminFormats.displayName(admin, member);
    final confirmed = await ConfirmationDialog.show(
      context,
      ConfirmationDialog(
        title: AppStrings.adminReactivateTitle(name),
        message: AppStrings.adminReactivateMessage,
        confirmLabel: AppStrings.adminReactivateShort,
      ),
    );
    if (!confirmed) return;

    final failure = await cubit.reactivate(admin);
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      failure?.userMessage ?? AppStrings.adminReactivated,
      isError: failure != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _reactivate(context),
      child: const Text(AppStrings.adminReactivateShort),
    );
  }
}

class _EmptyAdmins extends StatelessWidget {
  const _EmptyAdmins();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.admin_panel_settings_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.adminsEmptyTitle,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.adminsEmptyHint,
            style: AppTextStyles.bodyLargeMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AdminsSkeleton extends StatelessWidget {
  const _AdminsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          for (var row = 0; row < 4; row++) ...[
            const SkeletonBox(height: 104),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
