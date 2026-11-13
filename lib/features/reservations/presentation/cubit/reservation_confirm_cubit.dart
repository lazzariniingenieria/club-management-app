import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/reservation_draft.dart';
import '../../domain/usecases/create_reservation_use_case.dart';

sealed class ReservationConfirmState extends Equatable {
  const ReservationConfirmState();

  @override
  List<Object?> get props => [];
}

class ReservationConfirmIdle extends ReservationConfirmState {
  const ReservationConfirmIdle();
}

class ReservationConfirmSubmitting extends ReservationConfirmState {
  const ReservationConfirmSubmitting();
}

class ReservationConfirmSaved extends ReservationConfirmState {
  const ReservationConfirmSaved();
}

class ReservationConfirmTaken extends ReservationConfirmState {
  const ReservationConfirmTaken();
}

class ReservationConfirmFailure extends ReservationConfirmState {
  final String message;

  const ReservationConfirmFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class ReservationConfirmCubit extends Cubit<ReservationConfirmState> {
  final CreateReservationUseCase _createReservation;

  ReservationConfirmCubit(this._createReservation)
      : super(const ReservationConfirmIdle());

  Future<void> confirm(ReservationDraft draft) async {
    emit(const ReservationConfirmSubmitting());

    final result = await _createReservation(draft);
    if (isClosed) return;

    emit(
      result.fold<ReservationConfirmState>(
        _stateFor,
        (_) => const ReservationConfirmSaved(),
      ),
    );
  }

  static ReservationConfirmState _stateFor(Failure failure) {
    return failure is ConflictFailure
        ? const ReservationConfirmTaken()
        : ReservationConfirmFailure(failure.userMessage);
  }
}
