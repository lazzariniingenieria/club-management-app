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
  Future<Either<Failure, void>> createMember(MemberDraft draft) {
    return _guard('createMember', () async {
      await remoteDataSource.createMember(draft);

      return _announceRosterChange();
    });
  }

  @override
  Future<Either<Failure, void>> updateMember(int memberId, MemberDraft draft) {
    return _guard('updateMember', () async {
      await remoteDataSource.updateMember(memberId, draft);

      return _announceRosterChange();
    });
  }

  @override
  Future<Either<Failure, void>> setMemberActive(
    int memberId, {
    required bool isActive,
  }) {
    return _guard('setMemberActive', () async {
      await remoteDataSource.setMemberActive(memberId, isActive: isActive);

      return _announceRosterChange();
    });
  }

  @override
  Future<Either<Failure, void>> assignFamilyGroup(
    int memberId,
    int familyGroupId,
  ) {
    return _guard('assignFamilyGroup', () async {
      await remoteDataSource.assignFamilyGroup(memberId, familyGroupId);

      return _announceRosterChange();
    });
  }

  @override
  Future<Either<Failure, void>> removeFromFamilyGroup(int memberId) {
    return _guard('removeFromFamilyGroup', () async {
      await remoteDataSource.removeFromFamilyGroup(memberId);

      return _announceRosterChange();
    });
  }

  Either<Failure, void> _announceRosterChange() {
    _rosterChanges.add(null);

    return const Right(null);
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
