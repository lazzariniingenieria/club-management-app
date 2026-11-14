import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_sheet_frame.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/summary_table.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../domain/entities/recurring_slot.dart';
import '../cubit/recurring_slot_submit_cubit.dart';
import '../formatting/recurring_slot_formats.dart';
import '../widgets/renew_recurring_slot_sheet.dart';
import 'recurring_slot_detail_args.dart';

class RecurringSlotDetailScreen extends StatelessWidget {
  final RecurringSlotDetailArgs args;

  const RecurringSlotDetailScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecurringSlotSubmitCubit>(
      create: (_) => sl<RecurringSlotSubmitCubit>(),
      child: AdminScaffold(
        title: AppStrings.recurringSlotDetailTitle,
        body: _DetailBody(args: args),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final RecurringSlotDetailArgs args;

  const _DetailBody({required this.args});

  RecurringSlot get _slot => args.slot;

  String get _holder => RecurringSlotFormats.holder(
        _slot,
        args.overview.memberOf(_slot),
      );

  List<SummaryRow> get _rows => [
        SummaryRow(
          _slot.isActivity
              ? AppStrings.recurringSlotFormDescription
              : AppStrings.reservationFormMember,
          _holder,
        ),
        SummaryRow(
          AppStrings.reservationFormCourt,
          args.overview.courtOf(_slot)?.name ?? '',
        ),
        SummaryRow(
          AppStrings.recurringSlotWhen,
          RecurringSlotFormats.ofSlot(_slot),
        ),
        SummaryRow(
          AppStrings.recurringSlotValidity,
          RecurringSlotFormats.rangeOfSlot(_slot),
        ),
        SummaryRow(
          AppStrings.recurringSlotState,
          RecurringSlotFormats.state(_slot.state),
        ),
      ];

  void _onStateChanged(BuildContext context, RecurringSlotSubmitState state) {
    switch (state) {
      case RecurringSlotSubmitSaved():
        showAppSnackBar(context, AppStrings.recurringSlotDeactivated);
        context.pop();
      case RecurringSlotSubmitFailure(:final message):
        showAppSnackBar(context, message, isError: true);
      case RecurringSlotSubmitIdle():
      case RecurringSlotSubmitting():
      case RecurringSlotSubmitClashes():
        break;
    }
  }

  Future<void> _deactivate(BuildContext context) async {
    final cubit = context.read<RecurringSlotSubmitCubit>();
    final confirmed = await ConfirmationDialog.show(
      context,
      ConfirmationDialog(
        title: AppStrings.recurringSlotDeactivateTitle(_holder),
        message: AppStrings.recurringSlotDeactivateMessage,
        confirmLabel: AppStrings.recurringSlotDeactivate,
        dismissLabel: AppStrings.backAction,
        isDestructive: true,
      ),
    );
    if (confirmed) await cubit.deactivate(_slot);
  }

  Future<void> _renew(BuildContext context) async {
    final renewed = await showAppSheet<bool>(
      context,
      (_) => RenewRecurringSlotSheet(slot: _slot),
    );
    if (renewed != true || !context.mounted) return;

    showAppSnackBar(context, AppStrings.recurringSlotRenewed);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final notice = RecurringSlotFormats.expiryNotice(_slot, DateTime.now());

    return BlocConsumer<RecurringSlotSubmitCubit, RecurringSlotSubmitState>(
      listener: _onStateChanged,
      builder: (context, state) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (notice != null) ...[
            AppNotice(tone: AppNoticeTone.danger, message: notice),
            const SizedBox(height: AppSpacing.lg),
          ],
          SummaryTable(rows: _rows),
          const SizedBox(height: AppSpacing.xl),
          if (_slot.isActive)
            ..._actions(context, isBusy: state is RecurringSlotSubmitting)
          else
            const AppNotice(message: AppStrings.recurringSlotInactiveHint),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context, {required bool isBusy}) {
    return [
      AppButton(
        text: AppStrings.recurringSlotRenew,
        onPressed: isBusy ? null : () => _renew(context),
      ),
      const SizedBox(height: AppSpacing.md),
      TextButton(
        style: TextButton.styleFrom(foregroundColor: AppColors.dangerText),
        onPressed: isBusy ? null : () => _deactivate(context),
        child: const Text(AppStrings.recurringSlotDeactivate),
      ),
    ];
  }
}
