import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_sheet_frame.dart';
import '../../domain/entities/recurring_slot.dart';
import '../../domain/entities/recurring_slot_validity.dart';
import '../cubit/recurring_slot_submit_cubit.dart';
import 'clash_notice.dart';
import 'validity_field.dart';

class RenewRecurringSlotSheet extends StatelessWidget {
  final RecurringSlot slot;

  const RenewRecurringSlotSheet({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecurringSlotSubmitCubit>(
      create: (_) => sl<RecurringSlotSubmitCubit>(),
      child: _RenewForm(slot: slot),
    );
  }
}

class _RenewForm extends StatefulWidget {
  final RecurringSlot slot;

  const _RenewForm({required this.slot});

  @override
  State<_RenewForm> createState() => _RenewFormState();
}

class _RenewFormState extends State<_RenewForm> {
  late final DateTime _firstDay = RecurringSlotValidity.renewalStart(
    widget.slot.validUntil,
    _today(),
  );
  late RecurringSlotValidity _validity =
      RecurringSlotValidity.preset(_firstDay, ValidityPreset.suggested);

  static DateTime _today() {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day);
  }

  void _onStateChanged(BuildContext context, RecurringSlotSubmitState state) {
    if (state is RecurringSlotSubmitSaved) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecurringSlotSubmitCubit, RecurringSlotSubmitState>(
      listener: _onStateChanged,
      builder: (context, state) => AppSheetFrame(
        title: AppStrings.recurringSlotRenewTitle,
        children: [
          ..._outcome(state),
          ValidityField(
            value: _validity,
            firstDay: _firstDay,
            onChanged: (validity) => setState(() => _validity = validity),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: AppStrings.recurringSlotRenew,
            isLoading: state is RecurringSlotSubmitting,
            onPressed: () => context
                .read<RecurringSlotSubmitCubit>()
                .renew(widget.slot, _validity),
          ),
        ],
      ),
    );
  }

  List<Widget> _outcome(RecurringSlotSubmitState state) {
    final notice = switch (state) {
      RecurringSlotSubmitClashes(:final clashes) =>
        ClashNotice(clashes: clashes),
      RecurringSlotSubmitFailure(:final message) =>
        AppNotice(tone: AppNoticeTone.danger, message: message),
      _ => null,
    };
    if (notice == null) return const [];

    return [notice, const SizedBox(height: AppSpacing.lg)];
  }
}
