import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../domain/usecases/load_admin_summary_use_case.dart';
import 'admin_home_state.dart';

class AdminHomeCubit extends Cubit<AdminHomeState> {
  final LoadAdminSummaryUseCase _loadSummary;

  AdminHomeCubit(this._loadSummary) : super(const AdminHomeLoading());

  Future<void> load() async {
    emit(const AdminHomeLoading());

    final result = await _loadSummary();

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => AdminHomeFailure(failure.userMessage),
        AdminHomeReady.new,
      ),
    );
  }
}
