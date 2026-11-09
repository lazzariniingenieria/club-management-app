import 'package:equatable/equatable.dart';

import '../../domain/entities/court_block.dart';

sealed class CourtBlocksState extends Equatable {
  const CourtBlocksState();

  @override
  List<Object?> get props => [];
}

class CourtBlocksLoading extends CourtBlocksState {
  const CourtBlocksLoading();
}

class CourtBlocksReady extends CourtBlocksState {
  final List<CourtBlock> blocks;

  const CourtBlocksReady(this.blocks);

  @override
  List<Object?> get props => [blocks];
}

class CourtBlocksFailure extends CourtBlocksState {
  final bool isOffline;

  const CourtBlocksFailure({required this.isOffline});

  @override
  List<Object?> get props => [isOffline];
}
