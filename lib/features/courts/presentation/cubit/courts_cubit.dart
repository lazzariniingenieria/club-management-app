import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/court.dart';
import '../../domain/usecases/load_courts_use_case.dart';
import '../../domain/usecases/set_court_active_use_case.dart';
import '../../domain/usecases/watch_court_changes_use_case.dart';
import 'courts_state.dart';

class CourtsCubit extends Cubit<CourtsState> {
  final LoadCourtsUseCase _loadCourts;
  final SetCourtActiveUseCase _setCourtActive;
  late final StreamSubscription<void> _changes;

  CourtsCubit({
    required LoadCourtsUseCase loadCourts,
    required SetCourtActiveUseCase setCourtActive,
    required WatchCourtChangesUseCase watchChanges,
  })  : _loadCourts = loadCourts,
        _setCourtActive = setCourtActive,
        super(const CourtsLoading()) {
    _changes = watchChanges().listen((_) => load());
  }

  @override
  Future<void> close() async {
    await _changes.cancel();

    return super.close();
  }

  Future<void> load() async {
    if (state is! CourtsReady) emit(const CourtsLoading());

    final result = await _loadCourts();
    if (isClosed) return;

    emit(
      result.fold<CourtsState>(
        (failure) => CourtsFailure(isOffline: failure is NetworkFailure),
        CourtsReady.new,
      ),
    );
  }

  Future<Failure?> reactivate(Court court) async {
    final result = await _setCourtActive(court.id, isActive: true);

    return result.getLeft().toNullable();
  }
}
