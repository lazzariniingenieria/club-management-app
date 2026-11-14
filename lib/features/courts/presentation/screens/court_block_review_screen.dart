import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../reservations/domain/entities/block_impact.dart';
import '../../../reservations/domain/entities/reservation.dart';
import '../../../reservations/presentation/formatting/reservation_formats.dart';
import '../cubit/court_block_review_cubit.dart';
import '../formatting/court_block_formats.dart';
import 'court_block_review_args.dart';

class CourtBlockReviewScreen extends StatelessWidget {
  final CourtBlockReviewArgs args;

  const CourtBlockReviewScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CourtBlockReviewCubit>(
      create: (_) => sl<CourtBlockReviewCubit>(param1: args),
      child: AdminScaffold(
        title: AppStrings.courtBlockReviewTitle,
        body: _ReviewBody(args: args),
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  final CourtBlockReviewArgs args;

  const _ReviewBody({required this.args});

  void _onStateChanged(BuildContext context, CourtBlockReviewState state) {
    if (state.phase == CourtBlockReviewPhase.saved) {
      showAppSnackBar(context, AppStrings.courtBlockCreated);
      context.pop(true);
    } else if (state.error case final error?) {
      showAppSnackBar(context, error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CourtBlockReviewCubit, CourtBlockReviewState>(
      listener: _onStateChanged,
      builder: (context, state) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.hasChanged) ...[
            const AppNotice(
              tone: AppNoticeTone.danger,
              message: AppStrings.courtBlockReviewChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _BlockSummary(args: args),
          const SizedBox(height: AppSpacing.lg),
          ..._impact(state.impact),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: AppStrings.courtBlockReviewConfirm(
              state.impact.reservations.length,
            ),
            isLoading: state.phase == CourtBlockReviewPhase.submitting,
            onPressed: () => context
                .read<CourtBlockReviewCubit>()
                .confirm(args.court.id, args.draft),
          ),
        ],
      ),
    );
  }

  List<Widget> _impact(BlockImpact impact) {
    if (impact.cancelsNothing) {
      return const [AppNotice(message: AppStrings.courtBlockReviewNone)];
    }

    return [
      AppNotice(
        tone: AppNoticeTone.danger,
        message: AppStrings.courtBlockReviewWarning(
          impact.reservations.length,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      for (final reservation in impact.reservations)
        _AffectedReservation(reservation: reservation, impact: impact),
    ];
  }
}

class _BlockSummary extends StatelessWidget {
  final CourtBlockReviewArgs args;

  const _BlockSummary({required this.args});

  @override
  Widget build(BuildContext context) {
    final draft = args.draft;
    final lines = CourtBlockFormats.rangeOf(draft.startsAt, draft.endsAt);

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(args.court.name, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          for (final line in lines) Text(line, style: AppTextStyles.bodyLarge),
          Text(
            AppStrings.courtBlockReviewReason(
              draft.reason.isEmpty
                  ? AppStrings.courtBlockNoReason
                  : draft.reason,
            ),
            style: AppTextStyles.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _AffectedReservation extends StatelessWidget {
  final Reservation reservation;
  final BlockImpact impact;

  const _AffectedReservation({required this.reservation, required this.impact});

  @override
  Widget build(BuildContext context) {
    final when = '${CourtBlockFormats.day(reservation.date)} · '
        '${ReservationFormats.ofReservation(reservation)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
        ),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(when, style: AppTextStyles.labelLarge),
              Text(
                ReservationFormats.holderOf(
                  reservation,
                  impact.memberOf(reservation),
                ),
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
