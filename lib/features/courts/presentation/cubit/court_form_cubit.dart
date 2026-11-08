import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/court_draft.dart';
import '../../domain/usecases/save_court_use_case.dart';
import '../../domain/usecases/set_court_active_use_case.dart';
import 'court_form_state.dart';

class CourtFormCubit extends Cubit<CourtFormState> {
  final SaveCourtUseCase _saveCourt;
  final SetCourtActiveUseCase _setCourtActive;

  CourtFormCubit({
    required SaveCourtUseCase saveCourt,
    required SetCourtActiveUseCase setCourtActive,
  })  : _saveCourt = saveCourt,
        _setCourtActive = setCourtActive,
        super(const CourtFormEditing());

  Future<void> create(CourtDraft draft) {
    return _submit(() => _saveCourt.create(draft), CourtFormOutcome.created);
  }

  Future<void> update(int courtId, CourtDraft draft) {
    return _submit(
      () => _saveCourt.update(courtId, draft),
      CourtFormOutcome.updated,
    );
  }

  Future<void> setActive(int courtId, {required bool isActive}) {
    return _submit(
      () => _setCourtActive(courtId, isActive: isActive),
      isActive ? CourtFormOutcome.reactivated : CourtFormOutcome.deactivated,
    );
  }

  Future<void> _submit(
    Future<Either<Failure, void>> Function() run,
    CourtFormOutcome outcome,
  ) async {
    emit(const CourtFormSubmitting());

    final result = await run();
    if (isClosed) return;

    emit(
      result.fold<CourtFormState>(_stateFor, (_) => CourtFormSaved(outcome)),
    );
  }

  static CourtFormState _stateFor(Failure failure) {
    return failure is ConflictFailure
        ? const CourtFormConflict()
        : CourtFormFailure(failure.userMessage);
  }
}
