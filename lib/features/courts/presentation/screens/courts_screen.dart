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
import '../../domain/entities/court.dart';
import '../cubit/courts_cubit.dart';
import '../cubit/courts_state.dart';
import '../formatting/court_formats.dart';

class CourtsScreen extends StatelessWidget {
  const CourtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CourtsCubit>(
      create: (_) => sl<CourtsCubit>()..load(),
      child: const AdminScaffold(
        title: AppStrings.adminCourtsTitle,
        floatingActionButton: _NewCourtButton(),
        body: _CourtsBody(),
      ),
    );
  }
}

class _NewCourtButton extends StatelessWidget {
  const _NewCourtButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourtsCubit, CourtsState>(
      builder: (context, state) {
        if (state is! CourtsReady) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.adminCourtCreation),
          icon: const Icon(Icons.add_rounded),
          label: const Text(AppStrings.courtsNew),
        );
      },
    );
  }
}

class _CourtsBody extends StatelessWidget {
  const _CourtsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourtsCubit, CourtsState>(
      builder: (context, state) => switch (state) {
        CourtsLoading() => const _CourtsSkeleton(),
        CourtsFailure(:final isOffline) => StatusMessageView(
            icon: isOffline ? Icons.wifi_off_rounded : Icons.dns_outlined,
            title: AppStrings.courtsErrorTitle,
            message: isOffline
                ? AppStrings.networkErrorMessage
                : AppStrings.ledgerServerErrorMessage,
            actionLabel: AppStrings.retryAction,
            onAction: context.read<CourtsCubit>().load,
          ),
        CourtsReady(:final courts) => courts.isEmpty
            ? const _EmptyCourts()
            : _CourtList(courts: courts),
      },
    );
  }
}

class _CourtList extends StatelessWidget {
  final List<Court> courts;

  const _CourtList({required this.courts});

  static const double _floatingActionClearance = 96;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<CourtsCubit>().load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          _floatingActionClearance,
        ),
        itemCount: courts.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, index) => _CourtTile(court: courts[index]),
      ),
    );
  }
}

class _CourtTile extends StatelessWidget {
  final Court court;

  const _CourtTile({required this.court});

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
              onTap: () => context.push(
                AppRoutes.adminCourtEdition(court.id),
                extra: court,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _CourtIdentity(court: court),
              ),
            ),
          ),
          if (!court.isActive)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _ReactivateAction(court: court),
            ),
        ],
      ),
    );
  }
}

class _CourtIdentity extends StatelessWidget {
  final Court court;

  const _CourtIdentity({required this.court});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(court.name, style: AppTextStyles.labelLarge),
          Text(CourtFormats.details(court), style: AppTextStyles.bodyMedium),
          if (!court.isActive) ...[
            const SizedBox(height: AppSpacing.sm),
            const AppPill(
              label: AppStrings.courtStatusInactive,
              tone: AppPillTone.neutral,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReactivateAction extends StatelessWidget {
  final Court court;

  const _ReactivateAction({required this.court});

  Future<void> _reactivate(BuildContext context) async {
    final cubit = context.read<CourtsCubit>();
    final confirmed = await ConfirmationDialog.show(
      context,
      ConfirmationDialog(
        title: AppStrings.courtReactivateTitle(court.name),
        message: AppStrings.courtReactivateMessage,
        confirmLabel: AppStrings.courtReactivateShort,
      ),
    );
    if (!confirmed) return;

    final failure = await cubit.reactivate(court);
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      failure?.userMessage ?? AppStrings.courtReactivated,
      isError: failure != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _reactivate(context),
      child: const Text(AppStrings.courtReactivateShort),
    );
  }
}

class _EmptyCourts extends StatelessWidget {
  const _EmptyCourts();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sports_tennis_rounded,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.courtsEmptyTitle,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.courtsEmptyHint,
            style: AppTextStyles.bodyLargeMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CourtsSkeleton extends StatelessWidget {
  const _CourtsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          for (var row = 0; row < 3; row++) ...[
            const SkeletonBox(height: 80),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
