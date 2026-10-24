import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/family_group.dart';
import '../../domain/repositories/family_group_repository.dart';
import '../datasources/family_group_remote_data_source.dart';

class FamilyGroupRepositoryImpl implements FamilyGroupRepository {
  final FamilyGroupRemoteDataSource remoteDataSource;
  final AppLogger logger;

  FamilyGroupRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  static const String _logContext = 'FamilyGroupRepository';

  final _groupChanges = StreamController<void>.broadcast();

  @override
  Stream<void> get groupChanges => _groupChanges.stream;

  @override
  Future<Either<Failure, FamilyGroup>> loadGroup(int familyGroupId) {
    return _guard(
      'loadGroup',
      () async => Right(await remoteDataSource.fetchGroup(familyGroupId)),
    );
  }

  @override
  Future<Either<Failure, List<FamilyGroup>>> loadGroups() {
    return _guard(
      'loadGroups',
      () async => Right(await remoteDataSource.fetchGroups()),
    );
  }

  @override
  Future<Either<Failure, FamilyGroup>> createGroup({String? name}) {
    return _guard(
      'createGroup',
      () async => Right(await remoteDataSource.createGroup(name: name)),
    );
  }

  @override
  Future<Either<Failure, void>> renameGroup(int familyGroupId, String? name) {
    return _guard('renameGroup', () async {
      await remoteDataSource.renameGroup(familyGroupId, name);
      _groupChanges.add(null);

      return const Right(null);
    });
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
