import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/admin.dart';
import '../repositories/admin_repository.dart';

class SetAdminActiveUseCase {
  final AdminRepository repository;

  SetAdminActiveUseCase(this.repository);

  Future<Either<Failure, void>> call(
    Admin admin, {
    required bool isActive,
  }) async {
    final result =
        await repository.setAdminActive(admin.id, isActive: isActive);
    if (!_mayHaveApplied(result.getLeft().toNullable())) return result;

    return await _isApplied(admin, isActive) ? const Right(null) : result;
  }

  static bool _mayHaveApplied(Failure? failure) =>
      failure is ResponseTimeoutFailure || failure is NotFoundFailure;

  Future<bool> _isApplied(Admin admin, bool isActive) async {
    final listed = await repository.loadAdmins();

    return listed.fold((_) => false, (admins) {
      final current = admins.where((listed) => listed.id == admin.id);
      if (current.isEmpty) return !isActive && admin.isLinkedToMember;

      return current.first.isActive == isActive;
    });
  }
}
