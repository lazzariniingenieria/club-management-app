import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../courts/domain/entities/court_block_draft.dart';
import '../../../members/domain/repositories/member_repository.dart';
import '../entities/block_impact.dart';
import '../repositories/reservation_repository.dart';

class PreviewCourtBlockUseCase {
  final ReservationRepository reservations;
  final MemberRepository members;

  PreviewCourtBlockUseCase({required this.reservations, required this.members});

  Future<Either<Failure, BlockImpact>> call(
    int courtId,
    CourtBlockDraft block,
  ) async {
    final affected = await reservations.loadAffectedByBlock(courtId, block);
    final list = affected.getRight().toNullable();
    if (list == null) return Left(affected.getLeft().toNullable()!);
    if (list.isEmpty) return const Right(BlockImpact.none);

    final roster = await members.loadMembers();

    return roster.map(
      (roster) => BlockImpact(reservations: list, members: roster),
    );
  }
}
