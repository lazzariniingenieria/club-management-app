import 'package:equatable/equatable.dart';

enum AdminFormOutcome { created, updated, deactivated, reactivated }

sealed class AdminFormState extends Equatable {
  const AdminFormState();

  @override
  List<Object?> get props => [];
}

class AdminFormEditing extends AdminFormState {
  const AdminFormEditing();
}

class AdminFormSubmitting extends AdminFormState {
  const AdminFormSubmitting();
}

class AdminFormSaved extends AdminFormState {
  final AdminFormOutcome outcome;

  const AdminFormSaved(this.outcome);

  @override
  List<Object?> get props => [outcome];
}

class AdminFormConflict extends AdminFormState {
  const AdminFormConflict();
}

class AdminFormFailure extends AdminFormState {
  final String message;

  const AdminFormFailure(this.message);

  @override
  List<Object?> get props => [message];
}
