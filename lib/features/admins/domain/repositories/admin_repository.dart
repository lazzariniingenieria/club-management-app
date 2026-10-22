import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';

abstract class AdminRepository {
  Future<Either<Failure, void>> resetPassword(int adminId, String newPassword);
}
