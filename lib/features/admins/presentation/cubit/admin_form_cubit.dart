import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/admin.dart';
import '../../domain/entities/admin_draft.dart';
import '../../domain/usecases/reset_admin_password_use_case.dart';
import '../../domain/usecases/save_admin_use_case.dart';
import '../../domain/usecases/set_admin_active_use_case.dart';
import 'admin_form_state.dart';

class AdminFormCubit extends Cubit<AdminFormState> {
  final SaveAdminUseCase _saveAdmin;
  final SetAdminActiveUseCase _setAdminActive;
  final ResetAdminPasswordUseCase _resetPassword;

  AdminFormCubit({
    required SaveAdminUseCase saveAdmin,
    required SetAdminActiveUseCase setAdminActive,
    required ResetAdminPasswordUseCase resetPassword,
  })  : _saveAdmin = saveAdmin,
        _setAdminActive = setAdminActive,
        _resetPassword = resetPassword,
        super(const AdminFormEditing());

  Future<void> create(AdminDraft draft, String password) {
    return _submit(
      () => _saveAdmin.create(draft, password),
      AdminFormOutcome.created,
    );
  }

  Future<void> update(int adminId, AdminDraft draft) {
    return _submit(
      () => _saveAdmin.update(adminId, draft),
      AdminFormOutcome.updated,
    );
  }

  Future<void> setActive(Admin admin, {required bool isActive}) {
    return _submit(
      () => _setAdminActive(admin, isActive: isActive),
      _toggleOutcome(admin, isActive: isActive),
    );
  }

  Future<Failure?> resetPassword(int adminId, String newPassword) async {
    final result = await _resetPassword(adminId, newPassword);

    return result.getLeft().toNullable();
  }

  Future<void> _submit(
    Future<Either<Failure, void>> Function() run,
    AdminFormOutcome outcome,
  ) async {
    emit(const AdminFormSubmitting());

    final result = await run();
    if (isClosed) return;

    emit(result.fold<AdminFormState>(_stateFor, (_) => AdminFormSaved(outcome)));
  }

  static AdminFormOutcome _toggleOutcome(
    Admin admin, {
    required bool isActive,
  }) {
    if (isActive) return AdminFormOutcome.reactivated;

    return admin.isLinkedToMember
        ? AdminFormOutcome.keptAsMember
        : AdminFormOutcome.deactivated;
  }

  static AdminFormState _stateFor(Failure failure) {
    return failure is ConflictFailure
        ? const AdminFormConflict()
        : AdminFormFailure(failure.userMessage);
  }
}
