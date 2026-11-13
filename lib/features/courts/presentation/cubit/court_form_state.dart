import 'package:equatable/equatable.dart';

enum CourtFormOutcome { created, updated, deactivated, reactivated }

sealed class CourtFormState extends Equatable {
  const CourtFormState();

  @override
  List<Object?> get props => [];
}

class CourtFormEditing extends CourtFormState {
  const CourtFormEditing();
}

class CourtFormSubmitting extends CourtFormState {
  const CourtFormSubmitting();
}

class CourtFormSaved extends CourtFormState {
  final CourtFormOutcome outcome;

  const CourtFormSaved(this.outcome);

  @override
  List<Object?> get props => [outcome];
}

class CourtFormConflict extends CourtFormState {
  const CourtFormConflict();
}

class CourtFormFailure extends CourtFormState {
  final String message;

  const CourtFormFailure(this.message);

  @override
  List<Object?> get props => [message];
}
