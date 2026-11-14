import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/summary_table.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../cubit/recurring_slot_submit_cubit.dart';
import '../formatting/recurring_slot_formats.dart';
import '../widgets/clash_notice.dart';
import 'recurring_slot_confirmation_args.dart';

class RecurringSlotConfirmationScreen extends StatelessWidget {
  final RecurringSlotConfirmationArgs args;

  const RecurringSlotConfirmationScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecurringSlotSubmitCubit>(
      create: (_) => sl<RecurringSlotSubmitCubit>(),
      child: AdminScaffold(
        title: AppStrings.recurringSlotConfirmTitle,
        body: _ConfirmationBody(args: args),
      ),
    );
  }
}

class _ConfirmationBody extends StatelessWidget {
  final RecurringSlotConfirmationArgs args;

  const _ConfirmationBody({required this.args});

  void _onStateChanged(BuildContext context, RecurringSlotSubmitState state) {
    switch (state) {
      case RecurringSlotSubmitSaved():
        showAppSnackBar(context, AppStrings.recurringSlotCreated);
        context.pop(true);
      case RecurringSlotSubmitFailure(:final message):
        showAppSnackBar(context, message, isError: true);
      case RecurringSlotSubmitIdle():
      case RecurringSlotSubmitting():
      case RecurringSlotSubmitClashes():
        break;
    }
  }

  List<SummaryRow> get _rows {
    final draft = args.draft;
    final member = args.member;
    final dates = draft.dates(DateTime.now());

    return [
      member == null
          ? SummaryRow(
              AppStrings.recurringSlotFormDescription,
              draft.description?.trim() ?? '',
            )
          : SummaryRow(AppStrings.reservationFormMember, member.fullName),
      SummaryRow(AppStrings.reservationFormCourt, args.court.name),
      SummaryRow(
        AppStrings.recurringSlotWhen,
        RecurringSlotFormats.everyWeek(
          draft.weekday,
          draft.startTime,
          draft.endTime,
        ),
      ),
      SummaryRow(
        AppStrings.recurringSlotValidity,
        RecurringSlotFormats.range(draft.validity),
      ),
      SummaryRow(
        AppStrings.recurringSlotDates,
        AppStrings.recurringSlotReservedDates(dates.length),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecurringSlotSubmitCubit, RecurringSlotSubmitState>(
      listener: _onStateChanged,
      builder: (context, state) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state is RecurringSlotSubmitClashes) ...[
            ClashNotice(clashes: state.clashes),
            const SizedBox(height: AppSpacing.lg),
          ],
          SummaryTable(rows: _rows),
          ..._overdueNotice(),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: AppStrings.recurringSlotConfirmAction,
            isLoading: state is RecurringSlotSubmitting,
            onPressed: state is RecurringSlotSubmitClashes
                ? null
                : () =>
                    context.read<RecurringSlotSubmitCubit>().create(args.draft),
          ),
        ],
      ),
    );
  }

  List<Widget> _overdueNotice() {
    final member = args.member;
    if (member == null || !member.isOverdue) return const [];

    return [
      const SizedBox(height: AppSpacing.lg),
      AppNotice(
        message: AppStrings.recurringSlotOverdueWarning(
          member.fullName,
          member.daysOverdue,
        ),
      ),
    ];
  }
}
