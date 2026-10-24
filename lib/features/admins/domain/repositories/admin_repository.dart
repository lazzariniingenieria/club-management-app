import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/admin.dart';
import '../entities/admin_draft.dart';

abstract class AdminRepository {
  Stream<void> get adminChanges;

  Future<Either<Failure, List<Admin>>> loadAdmins();

  Future<Either<Failure, void>> createAdmin(AdminDraft draft, String password);

  Future<Either<Failure, void>> updateAdmin(int adminId, AdminDraft draft);

  Future<Either<Failure, void>> setAdminActive(
    int adminId, {
    required bool isActive,
  });

  Future<Either<Failure, void>> resetPassword(int adminId, String newPassword);
}
