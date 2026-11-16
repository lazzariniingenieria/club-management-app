import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../courts/domain/usecases/watch_court_changes_use_case.dart';
import '../../../members/domain/usecases/watch_roster_changes_use_case.dart';
import '../../domain/usecases/load_recurring_slot_overview_use_case.dart';
import '../../domain/usecases/watch_recurring_slot_changes_use_case.dart';
import 'recurring_slots_state.dart';

class RecurringSlotsCubit extends Cubit<RecurringSlotsState> {
  final LoadRecurringSlotOverviewUseCase _loadOverview;
  late final List<StreamSubscription<void>> _changes;

  RecurringSlotsCubit({
    required LoadRecurringSlotOverviewUseCase loadOverview,
    required WatchRecurringSlotChangesUseCase watchRecurringSlots,
    required WatchCourtChangesUseCase watchCourts,
    required WatchRosterChangesUseCase watchRoster,
  })  : _loadOverview = loadOverview,
        super(const RecurringSlotsLoading()) {
    _changes = [
      watchRecurringSlots().listen((_) => load()),
      watchCourts().listen((_) => load()),
      watchRoster().listen((_) => load()),
    ];
  }

  @override
  Future<void> close() async {
    for (final subscription in _changes) {
      await subscription.cancel();
    }

    return super.close();
  }

  Future<void> load() async {
    if (state is! RecurringSlotsReady) emit(const RecurringSlotsLoading());

    final result = await _loadOverview();
    if (isClosed) return;

    emit(
      result.fold<RecurringSlotsState>(
        (failure) =>
            RecurringSlotsFailure(isOffline: failure is NetworkFailure),
        RecurringSlotsReady.new,
      ),
    );
  }
}
