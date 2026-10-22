import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/family_group_candidates.dart';
import '../../domain/usecases/load_family_group_candidates_use_case.dart';
import 'family_group_picker_state.dart';

class FamilyGroupPickerCubit extends Cubit<FamilyGroupPickerState> {
  final LoadFamilyGroupCandidatesUseCase _loadCandidates;

  FamilyGroupPickerCubit(this._loadCandidates)
      : super(const FamilyGroupPickerLoading());

  Future<void> load() async {
    emit(const FamilyGroupPickerLoading());

    final result = await _loadCandidates();
    if (isClosed) return;

    emit(result.fold(_failureFrom, _readyFrom));
  }

  void search(String query) {
    final current = state;
    if (current is FamilyGroupPickerReady) emit(current.withQuery(query));
  }

  void clearSearch() => search('');

  static FamilyGroupPickerState _readyFrom(FamilyGroupCandidates candidates) =>
      FamilyGroupPickerReady(candidates: candidates);

  static FamilyGroupPickerState _failureFrom(Failure failure) =>
      FamilyGroupPickerFailure(isOffline: failure is NetworkFailure);
}
