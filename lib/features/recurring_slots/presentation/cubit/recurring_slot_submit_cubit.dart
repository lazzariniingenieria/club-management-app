import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/recurring_slot.dart';
import '../../domain/entities/recurring_slot_clash.dart';
import '../../domain/entities/recurring_slot_draft.dart';
import '../../domain/entities/recurring_slot_validity.dart';
import '../../domain/usecases/create_recurring_slot_use_case.dart';
import '../../domain/usecases/deactivate_recurring_slot_use_case.dart';
import '../../domain/usecases/renew_recurring_slot_use_case.dart';
import 'recurring_slot_submit_state.dart';

class RecurringSlotSubmitCubit extends Cubit<RecurringSlotSubmitState> {
  final CreateRecurringSlotUseCase _create;
  final RenewRecurringSlotUseCase _renew;
  final DeactivateRecurringSlotUseCase _deactivate;

  RecurringSlotSubmitCubit({
    required CreateRecurringSlotUseCase create,
    required RenewRecurringSlotUseCase renew,
    required DeactivateRecurringSlotUseCase deactivate,
  })  : _create = create,
        _renew = renew,
        _deactivate = deactivate,
        super(const RecurringSlotSubmitIdle());

  Future<void> create(RecurringSlotDraft draft) =>
      _submit(() => _create(draft));

  Future<void> renew(RecurringSlot slot, RecurringSlotValidity validity) =>
      _submit(() => _renew(slot, validity));

  Future<void> deactivate(RecurringSlot slot) =>
      _submit(() => _deactivate(slot.id));

  Future<void> _submit(Future<Either<Failure, Object?>> Function() run) async {
    if (state is RecurringSlotSubmitting) return;
    emit(const RecurringSlotSubmitting());

    final result = await run();
    if (isClosed) return;

    emit(result.fold(_stateFor, (_) => const RecurringSlotSubmitSaved()));
  }

  static RecurringSlotSubmitState _stateFor(Failure failure) {
    return switch (failure) {
      RecurringSlotClashFailure(:final clashes) =>
        RecurringSlotSubmitClashes(clashes),
      ConflictFailure() => const RecurringSlotSubmitClashes([]),
      ResponseTimeoutFailure() =>
        const RecurringSlotSubmitFailure(AppStrings.recurringSlotUnconfirmed),
      _ => RecurringSlotSubmitFailure(failure.userMessage),
    };
  }
}
