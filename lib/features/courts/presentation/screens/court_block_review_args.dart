import '../../../reservations/domain/entities/block_impact.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/court_block_draft.dart';

class CourtBlockReviewArgs {
  final Court court;
  final CourtBlockDraft draft;
  final BlockImpact impact;
  final bool hasChanged;

  const CourtBlockReviewArgs({
    required this.court,
    required this.draft,
    required this.impact,
    this.hasChanged = false,
  });
}
