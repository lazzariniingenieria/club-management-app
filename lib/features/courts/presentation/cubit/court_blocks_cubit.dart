import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/court_block.dart';
import '../../domain/usecases/load_court_blocks_use_case.dart';
import '../../domain/usecases/remove_court_block_use_case.dart';
import '../../domain/usecases/watch_court_block_changes_use_case.dart';
import 'court_blocks_state.dart';

class CourtBlocksCubit extends Cubit<CourtBlocksState> {
  final LoadCourtBlocksUseCase _loadBlocks;
  final RemoveCourtBlockUseCase _removeBlock;
  late final StreamSubscription<void> _changes;
  int? _courtId;

  CourtBlocksCubit({
    required LoadCourtBlocksUseCase loadBlocks,
    required RemoveCourtBlockUseCase removeBlock,
    required WatchCourtBlockChangesUseCase watchChanges,
  })  : _loadBlocks = loadBlocks,
        _removeBlock = removeBlock,
        super(const CourtBlocksLoading()) {
    _changes = watchChanges().listen((_) => reload());
  }

  @override
  Future<void> close() async {
    await _changes.cancel();

    return super.close();
  }

  Future<void> load(int courtId) async {
    _courtId = courtId;
    if (state is! CourtBlocksReady) emit(const CourtBlocksLoading());

    final result = await _loadBlocks(courtId);
    if (isClosed) return;

    emit(
      result.fold<CourtBlocksState>(
        (failure) => CourtBlocksFailure(isOffline: failure is NetworkFailure),
        CourtBlocksReady.new,
      ),
    );
  }

  Future<void> reload() async {
    final courtId = _courtId;
    if (courtId != null) await load(courtId);
  }

  Future<Failure?> remove(CourtBlock block) async {
    final result = await _removeBlock(block.courtId, block.id);

    return result.getLeft().toNullable();
  }
}
