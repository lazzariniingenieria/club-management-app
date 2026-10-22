import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/admin.dart';
import '../../domain/usecases/load_admins_use_case.dart';
import '../../domain/usecases/set_admin_active_use_case.dart';
import '../../domain/usecases/watch_admin_changes_use_case.dart';
import 'admins_state.dart';

class AdminsCubit extends Cubit<AdminsState> {
  final LoadAdminsUseCase _loadAdmins;
  final SetAdminActiveUseCase _setAdminActive;
  late final StreamSubscription<void> _changes;

  AdminsCubit({
    required LoadAdminsUseCase loadAdmins,
    required SetAdminActiveUseCase setAdminActive,
    required WatchAdminChangesUseCase watchChanges,
  })  : _loadAdmins = loadAdmins,
        _setAdminActive = setAdminActive,
        super(const AdminsLoading()) {
    _changes = watchChanges().listen((_) => load());
  }

  @override
  Future<void> close() async {
    await _changes.cancel();

    return super.close();
  }

  Future<void> load() async {
    if (state is! AdminsReady) emit(const AdminsLoading());

    final result = await _loadAdmins();
    if (isClosed) return;

    emit(
      result.fold(
        (failure) => AdminsFailure(isOffline: failure is NetworkFailure),
        AdminsReady.new,
      ),
    );
  }

  Future<Failure?> reactivate(Admin admin) async {
    final result = await _setAdminActive(admin.id, isActive: true);

    return result.getLeft().toNullable();
  }
}
