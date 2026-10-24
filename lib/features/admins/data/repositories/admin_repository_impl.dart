import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/admin.dart';
import '../../domain/entities/admin_draft.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;
  final AppLogger logger;

  AdminRepositoryImpl({required this.remoteDataSource, required this.logger});

  static const String _logContext = 'AdminRepository';

  final _adminChanges = StreamController<void>.broadcast();

  @override
  Stream<void> get adminChanges => _adminChanges.stream;

  @override
  Future<Either<Failure, List<Admin>>> loadAdmins() =>
      _guard('loadAdmins', remoteDataSource.fetchAdmins);

  @override
  Future<Either<Failure, void>> createAdmin(AdminDraft draft, String password) {
    return _guardChange(
      'createAdmin',
      () => remoteDataSource.createAdmin(draft, password),
    );
  }

  @override
  Future<Either<Failure, void>> updateAdmin(int adminId, AdminDraft draft) {
    return _guardChange(
      'updateAdmin',
      () => remoteDataSource.updateAdmin(adminId, draft),
    );
  }

  @override
  Future<Either<Failure, void>> setAdminActive(
    int adminId, {
    required bool isActive,
  }) {
    return _guardChange(
      'setAdminActive',
      () => remoteDataSource.setAdminActive(adminId, isActive: isActive),
    );
  }

  @override
  Future<Either<Failure, void>> resetPassword(int adminId, String newPassword) {
    return _guard(
      'resetPassword',
      () => remoteDataSource.resetPassword(adminId, newPassword),
    );
  }

  Future<Either<Failure, void>> _guardChange(
    String operation,
    Future<void> Function() run,
  ) async {
    final result = await _guard(operation, run);
    if (result.isRight()) _adminChanges.add(null);

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
