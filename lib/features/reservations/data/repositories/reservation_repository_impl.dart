import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/reservation_draft.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../datasources/reservation_remote_data_source.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  final ReservationRemoteDataSource remoteDataSource;
  final AppLogger logger;

  ReservationRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  static const String _logContext = 'ReservationRepository';

  final _reservationChanges = StreamController<void>.broadcast();

  @override
  Stream<void> get reservationChanges => _reservationChanges.stream;

  @override
  Future<Either<Failure, List<Reservation>>> loadReservations(DateTime day) {
    return _guard(
      'loadReservations',
      () => remoteDataSource.fetchReservations(day),
    );
  }

  @override
  Future<Either<Failure, List<Reservation>>> loadUpcoming(int courtId) {
    return _guard(
      'loadUpcoming',
      () => remoteDataSource.fetchUpcoming(courtId),
    );
  }

  @override
  Future<Either<Failure, void>> createReservation(ReservationDraft draft) {
    return _guardChange(
      'createReservation',
      () => remoteDataSource.createReservation(draft),
    );
  }

  @override
  Future<Either<Failure, void>> cancelReservation(int reservationId) {
    return _guardChange(
      'cancelReservation',
      () => remoteDataSource.cancelReservation(reservationId),
    );
  }

  Future<Either<Failure, void>> _guardChange(
    String operation,
    Future<void> Function() run,
  ) async {
    final result = await _guard(operation, run);
    final failure = result.getLeft().toNullable();
    final settled = failure is ConflictFailure || failure is NotFoundFailure;
    if (result.isRight() || settled) _reservationChanges.add(null);

    return result;
  }

  Future<Either<Failure, T>> _guard<T>(
    String operation,
    Future<T> Function() run,
  ) async {
    try {
      return Right(await run());
    } catch (error) {
      logger.error('$operation failed', context: _logContext, cause: error);

      return Left(failureFromException(error));
    }
  }
}
