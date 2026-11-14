import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court_block_draft.dart';
import 'package:club_management_app/features/courts/domain/usecases/create_court_block_use_case.dart';
import 'package:club_management_app/features/courts/presentation/cubit/court_block_form_cubit.dart';
import 'package:club_management_app/features/courts/presentation/cubit/court_block_form_state.dart';
import 'package:club_management_app/features/courts/presentation/cubit/court_block_review_cubit.dart';
import 'package:club_management_app/features/reservations/domain/entities/block_impact.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation.dart';
import 'package:club_management_app/features/reservations/domain/usecases/preview_court_block_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateCourtBlockUseCase extends Mock
    implements CreateCourtBlockUseCase {}

class MockPreviewCourtBlockUseCase extends Mock
    implements PreviewCourtBlockUseCase {}

Reservation at(int id, int hour) => Reservation(
      id: id,
      courtId: 3,
      memberId: 1,
      date: DateTime(2026, 12, 1),
      startTime: ClockTime(hour, 0),
      endTime: ClockTime(hour + 1, 0),
    );

BlockImpact impactOf(List<Reservation> reservations) =>
    BlockImpact(reservations: reservations, members: const []);

void main() {
  final draft = CourtBlockDraft(
    startsAt: DateTime(2026, 12, 1, 8),
    endsAt: DateTime(2026, 12, 1, 23),
    reason: 'Torneo',
  );
  late MockCreateCourtBlockUseCase create;
  late MockPreviewCourtBlockUseCase preview;

  setUpAll(() => registerFallbackValue(draft));

  setUp(() {
    create = MockCreateCourtBlockUseCase();
    preview = MockPreviewCourtBlockUseCase();
  });

  group('form', () {
    CourtBlockFormCubit build() =>
        CourtBlockFormCubit(createBlock: create, previewBlock: preview);

    test('a block that cancels nothing is created right away', () async {
      when(() => preview(3, any()))
          .thenAnswer((_) async => const Right(BlockImpact.none));
      when(() => create(3, any())).thenAnswer((_) async => const Right(null));
      final cubit = build();

      await cubit.create(3, draft);

      expect(cubit.state, const CourtBlockFormSaved());
      await cubit.close();
    });

    test('a block that cancels reservations asks for a review first', () async {
      when(() => preview(3, any()))
          .thenAnswer((_) async => Right(impactOf([at(45, 18)])));
      final cubit = build();

      await cubit.create(3, draft);

      expect(cubit.state, isA<CourtBlockFormNeedsReview>());
      verifyNever(() => create(any(), any()));
      await cubit.close();
    });
  });

  group('review', () {
    CourtBlockReviewCubit build(BlockImpact impact) => CourtBlockReviewCubit(
          createBlock: create,
          previewBlock: preview,
          impact: impact,
        );

    test('sends the ids it showed', () async {
      when(() => create(3, any())).thenAnswer((_) async => const Right(null));
      final cubit = build(impactOf([at(45, 18), at(46, 20)]));

      await cubit.confirm(3, draft);

      final sent = verify(() => create(3, captureAny())).captured.single
          as CourtBlockDraft;
      expect(sent.reservationIdsToCancel, [45, 46]);
      expect(cubit.state.phase, CourtBlockReviewPhase.saved);
      await cubit.close();
    });

    test('a reservation that appeared meanwhile shows the new list', () async {
      when(() => create(3, any()))
          .thenAnswer((_) async => const Left(ConflictFailure()));
      when(() => preview(3, draft)).thenAnswer(
        (_) async => Right(impactOf([at(45, 18), at(52, 20)])),
      );
      final cubit = build(impactOf([at(45, 18)]));

      await cubit.confirm(3, draft);

      expect(cubit.state.hasChanged, isTrue);
      expect(cubit.state.impact.reservationIds, [45, 52]);
      expect(cubit.state.phase, CourtBlockReviewPhase.reviewing);
      await cubit.close();
    });
  });
}
