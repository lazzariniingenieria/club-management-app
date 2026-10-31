import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/member_ledger.dart';
import '../../domain/entities/payment_draft.dart';
import '../../domain/entities/payment_precheck.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_data_source.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;
  final AppLogger logger;

  PaymentRepositoryImpl({required this.remoteDataSource, required this.logger});

  static const String _logContext = 'PaymentRepository';

  final _paymentChanges = StreamController<void>.broadcast();

  @override
  Stream<void> get paymentChanges => _paymentChanges.stream;

  @override
  Future<Either<Failure, MemberLedger>> loadLedger(int memberId) {
    return _guard(
      'loadLedger',
      () async => Right(await remoteDataSource.fetchLedger(memberId)),
    );
  }

  @override
  Future<Either<Failure, PaymentPrecheck>> loadPrecheck(int memberId) {
    return _guard(
      'loadPrecheck',
      () async => Right(await remoteDataSource.fetchPrecheck(memberId)),
    );
  }

  @override
  Future<Either<Failure, void>> recordPayment(PaymentDraft draft) {
    return _write(
      'recordPayment',
      () => remoteDataSource.recordPayment(draft),
    );
  }

  @override
  Future<Either<Failure, void>> recordPayments(List<PaymentDraft> drafts) {
    return _write(
      'recordPayments',
      () => remoteDataSource.recordPayments(drafts),
    );
  }

  @override
  Future<Either<Failure, void>> voidPayment(int paymentId, {String? reason}) {
    return _write(
      'voidPayment',
      () => remoteDataSource.voidPayment(paymentId, reason: reason),
    );
  }

  Future<Either<Failure, void>> _write(
    String operation,
    Future<void> Function() send,
  ) async {
    final result = await _send(operation, send);
    if (_mayHaveChangedPayments(result)) _paymentChanges.add(null);

    return result;
  }

  Future<Either<Failure, void>> _send(
    String operation,
    Future<void> Function() send,
  ) {
    return _guard<void>(operation, () async {
      await send();

      return const Right(null);
    });
  }

  static bool _mayHaveChangedPayments(Either<Failure, void> result) {
    return result.fold(
      (failure) =>
          failure is ResponseTimeoutFailure || failure is ConflictFailure,
      (_) => true,
    );
  }

  Future<Either<Failure, T>> _guard<T>(
    String operation,
    Future<Either<Failure, T>> Function() run,
  ) async {
    try {
      return await run();
    } catch (error) {
      logger.error('$operation failed', context: _logContext, cause: error);

      return Left(failureFromException(error));
    }
  }
}
