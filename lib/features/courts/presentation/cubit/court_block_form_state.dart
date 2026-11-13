import 'package:equatable/equatable.dart';

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

class CourtBlockFormFailure extends CourtBlockFormState {
  final String message;

  const CourtBlockFormFailure(this.message);

  @override
  List<Object?> get props => [message];
}
