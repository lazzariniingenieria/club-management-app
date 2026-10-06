import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';
import '../datasources/member_remote_data_source.dart';

class MemberRepositoryImpl implements MemberRepository {
  final MemberRemoteDataSource remoteDataSource;
  final AppLogger logger;

  MemberRepositoryImpl({required this.remoteDataSource, required this.logger});

  static const String _logContext = 'MemberRepository';

  @override
  Future<Either<Failure, List<Member>>> loadMembers() async {
    try {
      return Right(await remoteDataSource.fetchMembers());
    } catch (error) {
      logger.error('loadMembers failed', context: _logContext, cause: error);

      return Left(failureFromException(error));
    }
  }
}
