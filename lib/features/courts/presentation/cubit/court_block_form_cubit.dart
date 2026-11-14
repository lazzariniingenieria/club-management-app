import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../reservations/domain/usecases/preview_court_block_use_case.dart';
import '../../domain/entities/court_block_draft.dart';
import '../../domain/usecases/create_court_block_use_case.dart';
import 'court_block_form_state.dart';

class CourtBlockFormCubit extends Cubit<CourtBlockFormState> {
  final CreateCourtBlockUseCase _createBlock;
  final PreviewCourtBlockUseCase _previewBlock;

  CourtBlockFormCubit({
    required CreateCourtBlockUseCase createBlock,
    required PreviewCourtBlockUseCase previewBlock,
  })  : _createBlock = createBlock,
        _previewBlock = previewBlock,
        super(const CourtBlockFormEditing());

  Future<void> create(int courtId, CourtBlockDraft draft) async {
    if (state is CourtBlockFormSubmitting) return;
    emit(const CourtBlockFormSubmitting());

    final block = draft.trimmed();
    final impact = await _previewBlock(courtId, block);
    if (isClosed) return;

    final cancelsSomething =
        impact.getRight().toNullable()?.cancelsNothing == false;
    if (impact.isLeft() || cancelsSomething) {
      emit(
        impact.fold(
          (failure) => CourtBlockFormFailure(messageFor(failure)),
          (impact) => CourtBlockFormNeedsReview(draft: block, impact: impact),
        ),
      );
      return;
    }

    await _createWithoutCancelling(courtId, block);
  }

  void backToEditing() => emit(const CourtBlockFormEditing());

  Future<void> _createWithoutCancelling(
    int courtId,
    CourtBlockDraft block,
  ) async {
    final result = await _createBlock(courtId, block);
    if (isClosed) return;

    final failure = result.getLeft().toNullable();
    if (failure is ConflictFailure) return _reviewAgain(courtId, block);

    emit(
      failure == null
          ? const CourtBlockFormSaved()
          : CourtBlockFormFailure(messageFor(failure)),
    );
  }

  Future<void> _reviewAgain(int courtId, CourtBlockDraft block) async {
    final impact = await _previewBlock(courtId, block);
    if (isClosed) return;

    emit(
      impact.fold(
        (failure) => CourtBlockFormFailure(messageFor(failure)),
        (impact) => CourtBlockFormNeedsReview(
          draft: block,
          impact: impact,
          hasChanged: true,
        ),
      ),
    );
  }

  static String messageFor(Failure failure) {
    return failure is ResponseTimeoutFailure
        ? AppStrings.courtBlockUnconfirmed
        : failure.userMessage;
  }
}
