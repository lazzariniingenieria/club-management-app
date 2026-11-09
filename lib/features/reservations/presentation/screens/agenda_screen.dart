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
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/status_message_view.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../courts/domain/entities/court_block.dart';
import '../../../courts/presentation/formatting/court_block_formats.dart';
import '../../domain/entities/day_agenda.dart';
import '../../domain/entities/reservation.dart';
import '../cubit/agenda_cubit.dart';
import '../cubit/agenda_state.dart';
import '../formatting/reservation_formats.dart';
import '../widgets/agenda_day_navigator.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AgendaCubit>(
      create: (_) => sl<AgendaCubit>()..load(),
      child: const AdminScaffold(
        title: AppStrings.agendaTitle,
        showsRoleBadge: true,
        floatingActionButton: _NewReservationButton(),
        body: _AgendaBody(),
      ),
    );
  }
}

class _NewReservationButton extends StatelessWidget {
  const _NewReservationButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgendaCubit, AgendaState>(
      builder: (context, state) {
        if (state is! AgendaReady || state.agenda.courts.isEmpty) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          onPressed: () => context.push(
            AppRoutes.adminReservationCreation,
            extra: state.day,
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text(AppStrings.agendaNew),
        );
      },
    );
  }
}

class _AgendaBody extends StatelessWidget {
  const _AgendaBody();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AgendaCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<AgendaCubit, AgendaState>(
          buildWhen: (previous, current) => previous.day != current.day,
          builder: (context, state) => AgendaDayNavigator(
            day: state.day,
            onDayChanged: cubit.showDay,
          ),
        ),
        const Expanded(child: _AgendaContent()),
      ],
    );
  }
}

class _AgendaContent extends StatelessWidget {
  const _AgendaContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgendaCubit, AgendaState>(
      builder: (context, state) => switch (state) {
        AgendaLoading() => const _AgendaSkeleton(),
        AgendaFailure(:final isOffline) => StatusMessageView(
            icon: isOffline ? Icons.wifi_off_rounded : Icons.dns_outlined,
            title: AppStrings.agendaErrorTitle,
            message: isOffline
                ? AppStrings.networkErrorMessage
                : AppStrings.ledgerServerErrorMessage,
            actionLabel: AppStrings.retryAction,
            onAction: context.read<AgendaCubit>().load,
          ),
        AgendaReady(:final agenda) => agenda.courts.isEmpty
            ? const _NoActiveCourts()
            : _AgendaList(agenda: agenda),
      },
    );
  }
}

class _NoActiveCourts extends StatelessWidget {
  const _NoActiveCourts();

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
            AppStrings.agendaNoCourtsTitle,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.agendaNoCourtsHint,
            style: AppTextStyles.bodyLargeMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AgendaList extends StatelessWidget {
  final DayAgenda agenda;

  const _AgendaList({required this.agenda});

  static const double _floatingActionClearance = 96;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<AgendaCubit>().load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          _floatingActionClearance,
        ),
        itemCount: agenda.courts.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (_, index) => _CourtDay(
          courtAgenda: agenda.courts[index],
          agenda: agenda,
        ),
      ),
    );
  }
}

class _CourtDay extends StatelessWidget {
  final CourtAgenda courtAgenda;
  final DayAgenda agenda;

  const _CourtDay({required this.courtAgenda, required this.agenda});

  bool get _isFree =>
      courtAgenda.reservations.isEmpty && courtAgenda.blocks.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            courtAgenda.court.name,
            style: AppTextStyles.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_isFree)
          Text(AppStrings.agendaFreeDay, style: AppTextStyles.bodyLargeMuted),
        for (final block in courtAgenda.blocks) _BlockLine(block: block),
        for (final reservation in courtAgenda.reservations)
          _ReservationTile(
            reservation: reservation,
            courtName: courtAgenda.court.name,
            agenda: agenda,
          ),
      ],
    );
  }
}

class _BlockLine extends StatelessWidget {
  final CourtBlock block;

  const _BlockLine({required this.block});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.infoSurface,
          borderRadius: AppRadius.mdAll,
        ),
        child: Text(
          ReservationFormats.blockOfTheDay(block),
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final Reservation reservation;
  final String courtName;
  final DayAgenda agenda;

  const _ReservationTile({
    required this.reservation,
    required this.courtName,
    required this.agenda,
  });

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<AgendaCubit>();
    final holder = ReservationFormats.holder(agenda.memberOf(reservation));
    final when = '${CourtBlockFormats.day(reservation.date)}, '
        '${ReservationFormats.ofReservation(reservation)}';
    final confirmed = await ConfirmationDialog.show(
      context,
      ConfirmationDialog(
        title: AppStrings.reservationCancelTitle(holder),
        message: AppStrings.reservationCancelMessage(courtName, when),
        confirmLabel: AppStrings.reservationCancelConfirm,
        dismissLabel: AppStrings.backAction,
        isDestructive: true,
      ),
    );
    if (!confirmed) return;

    final failure = await cubit.cancel(reservation);
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      failure?.userMessage ?? AppStrings.reservationCancelled,
      isError: failure != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: _ReservationDetails(
                  hours: ReservationFormats.ofReservation(reservation),
                  holder: ReservationFormats.holder(
                    agenda.memberOf(reservation),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _cancel(context),
                child: const Text(AppStrings.reservationCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationDetails extends StatelessWidget {
  final String hours;
  final String holder;

  const _ReservationDetails({required this.hours, required this.holder});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hours, style: AppTextStyles.labelLarge),
          Text(holder, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _AgendaSkeleton extends StatelessWidget {
  const _AgendaSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          for (var row = 0; row < 3; row++) ...[
            const SkeletonBox(height: 96),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
