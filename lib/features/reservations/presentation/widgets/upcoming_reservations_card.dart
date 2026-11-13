import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/inline_error_card.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../domain/entities/day_agenda.dart';
import '../cubit/upcoming_reservations_cubit.dart';
import '../formatting/reservation_formats.dart';

class UpcomingReservationsCard extends StatelessWidget {
  final VoidCallback onOpenAgenda;

  const UpcomingReservationsCard({super.key, required this.onOpenAgenda});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpcomingReservationsCubit, UpcomingReservationsState>(
      builder: (context, state) => switch (state) {
        UpcomingReservationsHidden() => const SizedBox.shrink(),
        UpcomingReservationsLoading() => const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl),
            child: SkeletonBox(height: 120, borderRadius: AppRadius.lgAll),
          ),
        UpcomingReservationsFailure(:final isOffline) => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: InlineErrorCard(
              title: AppStrings.upcomingReservationsErrorTitle,
              message: isOffline
                  ? AppStrings.networkErrorMessage
                  : AppStrings.ledgerServerErrorMessage,
              onRetry: context.read<UpcomingReservationsCubit>().load,
            ),
          ),
        UpcomingReservationsReady(:final agenda, :final upcoming) => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: _UpcomingPanel(
              agenda: agenda,
              upcoming: upcoming,
              onTap: onOpenAgenda,
            ),
          ),
      },
    );
  }
}

class _UpcomingPanel extends StatelessWidget {
  final DayAgenda agenda;
  final List<UpcomingReservation> upcoming;
  final VoidCallback onTap;

  const _UpcomingPanel({
    required this.agenda,
    required this.upcoming,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.infoSurface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PanelHeader(),
              const SizedBox(height: AppSpacing.sm),
              if (upcoming.isEmpty)
                Text(
                  AppStrings.upcomingReservationsNoneLeft,
                  style: AppTextStyles.bodyMedium,
                ),
              for (final item in upcoming)
                _UpcomingRow(item: item, agenda: agenda),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.upcomingReservationsOpenAgenda,
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppStrings.upcomingReservationsTitle.toUpperCase(),
              style: AppTextStyles.sectionLabel.copyWith(
                color: AppColors.brandNavy,
              ),
            ),
          ),
          Text(
            AppStrings.upcomingReservationsSeeAgenda,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.accentBlue,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.accentBlue),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  final UpcomingReservation item;
  final DayAgenda agenda;

  const _UpcomingRow({required this.item, required this.agenda});

  @override
  Widget build(BuildContext context) {
    final reservation = item.reservation;

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ReservationFormats.holderOf(
                      reservation,
                      agenda.memberOf(reservation),
                    ),
                    style: AppTextStyles.labelLarge,
                  ),
                  Text(item.court.name, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              ReservationFormats.ofReservation(reservation),
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.accentBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
