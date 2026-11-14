import 'package:equatable/equatable.dart';

import '../../../reservations/domain/entities/block_impact.dart';
import '../../domain/entities/court_block_draft.dart';

sealed class CourtBlockFormState extends Equatable {
  const CourtBlockFormState();

  @override
  List<Object?> get props => [];
}

class CourtBlockFormEditing extends CourtBlockFormState {
  const CourtBlockFormEditing();
}

class CourtBlockFormSubmitting extends CourtBlockFormState {
  const CourtBlockFormSubmitting();
}

class CourtBlockFormSaved extends CourtBlockFormState {
  const CourtBlockFormSaved();
}

class CourtBlockFormNeedsReview extends CourtBlockFormState {
  final CourtBlockDraft draft;
  final BlockImpact impact;
  final bool hasChanged;

  const CourtBlockFormNeedsReview({
    required this.draft,
    required this.impact,
    this.hasChanged = false,
  });

  @override
  List<Object?> get props => [draft, impact, hasChanged];
}

class CourtBlockFormFailure extends CourtBlockFormState {
  final String message;

  const CourtBlockFormFailure(this.message);

  @override
  List<Object?> get props => [message];
}
