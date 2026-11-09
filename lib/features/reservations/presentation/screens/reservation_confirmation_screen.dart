import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/summary_table.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../courts/presentation/formatting/court_block_formats.dart';
import '../cubit/reservation_confirm_cubit.dart';
import '../formatting/reservation_formats.dart';
import 'reservation_confirmation_args.dart';

class ReservationConfirmationScreen extends StatelessWidget {
  final ReservationConfirmationArgs args;

  const ReservationConfirmationScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReservationConfirmCubit>(
      create: (_) => sl<ReservationConfirmCubit>(),
      child: AdminScaffold(
        title: AppStrings.reservationConfirmTitle,
        body: _ConfirmationBody(args: args),
      ),
    );
  }
}

class _ConfirmationBody extends StatelessWidget {
  final ReservationConfirmationArgs args;

  const _ConfirmationBody({required this.args});

  void _onStateChanged(BuildContext context, ReservationConfirmState state) {
    switch (state) {
      case ReservationConfirmSaved():
        showAppSnackBar(context, AppStrings.reservationConfirmed);
        context.go(AppRoutes.adminReservations);
      case ReservationConfirmFailure(:final message):
        showAppSnackBar(context, message, isError: true);
      case ReservationConfirmIdle():
      case ReservationConfirmSubmitting():
      case ReservationConfirmTaken():
        break;
    }
  }

  List<SummaryRow> get _rows => [
        SummaryRow(AppStrings.reservationFormMember, args.member.fullName),
        SummaryRow(AppStrings.reservationFormCourt, args.court.name),
        SummaryRow(
          AppStrings.reservationFormDay,
          CourtBlockFormats.day(args.draft.date),
        ),
        SummaryRow(
          AppStrings.reservationFormStart,
          ReservationFormats.hours(args.draft.startTime, args.draft.endTime),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReservationConfirmCubit, ReservationConfirmState>(
      listener: _onStateChanged,
      builder: (context, state) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state is ReservationConfirmTaken) ...[
            const AppNotice(
              tone: AppNoticeTone.danger,
              message: AppStrings.reservationSlotTaken,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          SummaryTable(rows: _rows),
          if (args.member.isOverdue) ...[
            const SizedBox(height: AppSpacing.lg),
            AppNotice(
              tone: AppNoticeTone.info,
              message: AppStrings.reservationOverdueWarning(
                args.member.fullName,
                args.member.daysOverdue,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: AppStrings.reservationConfirmAction,
            isLoading: state is ReservationConfirmSubmitting,
            onPressed: state is ReservationConfirmTaken
                ? null
                : () => context.read<ReservationConfirmCubit>().confirm(
                      args.draft,
                    ),
          ),
        ],
      ),
    );
  }
}
