import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../reservations/domain/entities/block_impact.dart';
import '../../../reservations/domain/usecases/preview_court_block_use_case.dart';
import '../../domain/entities/court_block_draft.dart';
import '../../domain/usecases/create_court_block_use_case.dart';
import 'court_block_form_cubit.dart';

enum CourtBlockReviewPhase { reviewing, submitting, saved }

class CourtBlockReviewState extends Equatable {
  final BlockImpact impact;
  final CourtBlockReviewPhase phase;
  final bool hasChanged;
  final String? error;

  const CourtBlockReviewState({
    required this.impact,
    this.phase = CourtBlockReviewPhase.reviewing,
    this.hasChanged = false,
    this.error,
  });

  @override
  List<Object?> get props => [impact, phase, hasChanged, error];
}

class CourtBlockReviewCubit extends Cubit<CourtBlockReviewState> {
  final CreateCourtBlockUseCase _createBlock;
  final PreviewCourtBlockUseCase _previewBlock;

  CourtBlockReviewCubit({
    required CreateCourtBlockUseCase createBlock,
    required PreviewCourtBlockUseCase previewBlock,
    required BlockImpact impact,
    bool hasChanged = false,
  })  : _createBlock = createBlock,
        _previewBlock = previewBlock,
        super(CourtBlockReviewState(impact: impact, hasChanged: hasChanged));

  Future<void> confirm(int courtId, CourtBlockDraft draft) async {
    if (state.phase != CourtBlockReviewPhase.reviewing) return;
    emit(_with(phase: CourtBlockReviewPhase.submitting));

    final block = draft.cancelling(state.impact.reservationIds);
    final result = await _createBlock(courtId, block);
    if (isClosed) return;

    final failure = result.getLeft().toNullable();
    if (failure == null) {
      emit(_with(phase: CourtBlockReviewPhase.saved));
    } else if (failure is ConflictFailure) {
      await _reviewAgain(courtId, draft);
    } else {
      emit(_with(error: CourtBlockFormCubit.messageFor(failure)));
    }
  }

  Future<void> _reviewAgain(int courtId, CourtBlockDraft draft) async {
    final impact = await _previewBlock(courtId, draft);
    if (isClosed) return;

    emit(
      impact.fold(
        (failure) => _with(error: CourtBlockFormCubit.messageFor(failure)),
        (impact) => CourtBlockReviewState(impact: impact, hasChanged: true),
      ),
    );
  }

  CourtBlockReviewState _with({
    CourtBlockReviewPhase phase = CourtBlockReviewPhase.reviewing,
    String? error,
  }) {
    return CourtBlockReviewState(
      impact: state.impact,
      phase: phase,
      hasChanged: state.hasChanged,
      error: error,
    );
  }
}
