import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/recurring_slot.dart';
import '../../domain/entities/recurring_slot_clash.dart';
import '../../domain/entities/recurring_slot_draft.dart';
import '../../domain/entities/recurring_slot_validity.dart';
import '../../domain/repositories/recurring_slot_repository.dart';
import '../datasources/recurring_slot_remote_data_source.dart';
import '../models/recurring_slot_model.dart';

class RecurringSlotRepositoryImpl implements RecurringSlotRepository {
  final RecurringSlotRemoteDataSource remoteDataSource;
  final AppLogger logger;

  RecurringSlotRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  static const String _logContext = 'RecurringSlotRepository';

  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get recurringSlotChanges => _changes.stream;

  @override
  Future<Either<Failure, List<RecurringSlot>>> loadRecurringSlots() {
    return _guard(
      'loadRecurringSlots',
      remoteDataSource.fetchRecurringSlots,
    );
  }

  @override
  Future<Either<Failure, RecurringSlot>> createRecurringSlot(
    RecurringSlotDraft draft,
  ) {
    return _guardChange(
      'createRecurringSlot',
      () => remoteDataSource.createRecurringSlot(draft),
    );
  }

  @override
  Future<Either<Failure, RecurringSlot>> renewRecurringSlot(
    int recurringSlotId,
    RecurringSlotValidity validity,
  ) {
    return _guardChange(
      'renewRecurringSlot',
      () => remoteDataSource.renewRecurringSlot(recurringSlotId, validity),
    );
  }

  @override
  Future<Either<Failure, void>> deactivateRecurringSlot(int recurringSlotId) {
    return _guardChange(
      'deactivateRecurringSlot',
      () => remoteDataSource.deactivateRecurringSlot(recurringSlotId),
    );
  }

  Future<Either<Failure, T>> _guardChange<T>(
    String operation,
    Future<T> Function() run,
  ) async {
    final result = await _guard(operation, run);
    final failure = result.getLeft().toNullable();
    final mayHaveChanged = failure is ResponseTimeoutFailure ||
        (failure is ConflictFailure && failure is! RecurringSlotClashFailure);
    if (result.isRight() || mayHaveChanged) _changes.add(null);

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

      return Left(_failureOf(error));
    }
  }

  static Failure _failureOf(Object error) {
    if (error is ConflictException) {
      final clashes = RecurringSlotModel.clashesFromDetails(error.details);
      if (clashes.isNotEmpty) return RecurringSlotClashFailure(clashes);
    }

    return failureFromException(error);
  }
}
