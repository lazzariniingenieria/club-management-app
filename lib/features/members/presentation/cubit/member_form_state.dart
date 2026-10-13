import 'package:equatable/equatable.dart';

enum MemberFormOutcome { created, updated, deactivated, reactivated }

sealed class MemberFormState extends Equatable {
  const MemberFormState();

  @override
  List<Object?> get props => [];
}

class MemberFormEditing extends MemberFormState {
  const MemberFormEditing();
}

class MemberFormSubmitting extends MemberFormState {
  const MemberFormSubmitting();
}

class MemberFormSaved extends MemberFormState {
  final MemberFormOutcome outcome;

  const MemberFormSaved(this.outcome);

  @override
  List<Object?> get props => [outcome];
}

class MemberFormDuplicatedDni extends MemberFormState {
  const MemberFormDuplicatedDni();
}

class MemberFormFailure extends MemberFormState {
  final String message;

  const MemberFormFailure(this.message);

  @override
  List<Object?> get props => [message];
}
