import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/court_block_draft.dart';
import '../../domain/usecases/create_court_block_use_case.dart';
import 'court_block_form_state.dart';

class CourtBlockFormCubit extends Cubit<CourtBlockFormState> {
  final CreateCourtBlockUseCase _createBlock;

  CourtBlockFormCubit(this._createBlock) : super(const CourtBlockFormEditing());

  Future<void> create(int courtId, CourtBlockDraft draft) async {
    emit(const CourtBlockFormSubmitting());

    final result = await _createBlock(courtId, draft);
    if (isClosed) return;

    emit(
      result.fold<CourtBlockFormState>(
        (failure) => CourtBlockFormFailure(_messageFor(failure)),
        (_) => const CourtBlockFormSaved(),
      ),
    );
  }

  static String _messageFor(Failure failure) {
    return failure is ResponseTimeoutFailure
        ? AppStrings.courtBlockUnconfirmed
        : failure.userMessage;
  }
}
