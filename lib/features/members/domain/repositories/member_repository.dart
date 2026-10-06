import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/member.dart';

abstract class MemberRepository {
  Future<Either<Failure, List<Member>>> loadMembers();
}
