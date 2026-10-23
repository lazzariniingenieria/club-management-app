import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/member_draft.dart';
import '../../domain/repositories/member_repository.dart';
import '../datasources/member_remote_data_source.dart';

class MemberRepositoryImpl implements MemberRepository {
  final MemberRemoteDataSource remoteDataSource;
  final AppLogger logger;

  MemberRepositoryImpl({required this.remoteDataSource, required this.logger});

  static const String _logContext = 'MemberRepository';

  final _rosterChanges = StreamController<void>.broadcast();

  @override
  Stream<void> get rosterChanges => _rosterChanges.stream;

  @override
  Future<Either<Failure, List<Member>>> loadMembers() {
    return _guard(
      'loadMembers',
      () async => Right(await remoteDataSource.fetchMembers()),
    );
  }

  @override
  Future<Either<Failure, Member>> loadMember(int memberId) {
    return _guard(
      'loadMember',
      () async => Right(await remoteDataSource.fetchMember(memberId)),
    );
  }

  @override
  Future<Either<Failure, void>> createMember(MemberDraft draft) {
    return _write('createMember', () => remoteDataSource.createMember(draft));
  }

  @override
  Future<Either<Failure, void>> updateMember(int memberId, MemberDraft draft) {
    return _write(
      'updateMember',
      () => remoteDataSource.updateMember(memberId, draft),
    );
  }

  @override
  Future<Either<Failure, void>> setMemberActive(
    int memberId, {
    required bool isActive,
  }) {
    return _write(
      'setMemberActive',
      () => remoteDataSource.setMemberActive(memberId, isActive: isActive),
    );
  }

  @override
  Future<Either<Failure, void>> assignFamilyGroup(
    int memberId,
    int familyGroupId,
  ) {
    return _write(
      'assignFamilyGroup',
      () => remoteDataSource.assignFamilyGroup(memberId, familyGroupId),
    );
  }

  @override
  Future<Either<Failure, void>> removeFromFamilyGroup(int memberId) {
    return _write(
      'removeFromFamilyGroup',
      () => remoteDataSource.removeFromFamilyGroup(memberId),
    );
  }

  Future<Either<Failure, void>> _write(
    String operation,
    Future<void> Function() send,
  ) async {
    final result = await _guard<void>(operation, () async {
      await send();

      return const Right(null);
    });
    if (_mayHaveChangedRoster(result)) _rosterChanges.add(null);

    return result;
  }

  static bool _mayHaveChangedRoster(Either<Failure, void> result) {
    return result.fold(
      (failure) => failure is ResponseTimeoutFailure,
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
