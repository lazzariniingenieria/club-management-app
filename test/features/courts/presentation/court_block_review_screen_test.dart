import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court.dart';
import 'package:club_management_app/features/courts/domain/entities/court_block_draft.dart';
import 'package:club_management_app/features/courts/domain/usecases/create_court_block_use_case.dart';
import 'package:club_management_app/features/courts/presentation/cubit/court_block_review_cubit.dart';
import 'package:club_management_app/features/courts/presentation/screens/court_block_review_args.dart';
import 'package:club_management_app/features/courts/presentation/screens/court_block_review_screen.dart';
import 'package:club_management_app/features/reservations/domain/entities/block_impact.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation.dart';
import 'package:club_management_app/features/reservations/domain/usecases/preview_court_block_use_case.dart';
import 'package:club_management_app/features/reservations/presentation/formatting/reservation_formats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateCourtBlockUseCase extends Mock
    implements CreateCourtBlockUseCase {}

class MockPreviewCourtBlockUseCase extends Mock
    implements PreviewCourtBlockUseCase {}

const int affectedCount = 60;
const int slotsPerDay = 14;

Reservation affected(int index) => Reservation(
      id: index + 1,
      courtId: 3,
      memberId: 1,
      date: DateTime(2026, 12, 1 + index ~/ slotsPerDay),
      startTime: ClockTime(8 + index % slotsPerDay, 0),
      endTime: ClockTime(9 + index % slotsPerDay, 0),
    );

void main() {
  final reservations = [
    for (var index = 0; index < affectedCount; index++) affected(index),
  ];
  final args = CourtBlockReviewArgs(
    court: const Court(
      id: 3,
      name: 'Cancha de Tenis 1',
      openingTime: ClockTime(8, 0),
      closingTime: ClockTime(23, 0),
      isActive: true,
    ),
    draft: CourtBlockDraft(
      startsAt: DateTime(2026, 12, 1, 8),
      endsAt: DateTime(2026, 12, 5, 23),
      reason: 'Torneo',
    ),
    impact: BlockImpact(reservations: reservations, members: const []),
  );

  setUp(() {
    sl.registerFactoryParam<CourtBlockReviewCubit, CourtBlockReviewArgs, void>(
      (args, _) => CourtBlockReviewCubit(
        createBlock: MockCreateCourtBlockUseCase(),
        previewBlock: MockPreviewCourtBlockUseCase(),
        impact: args.impact,
      ),
    );
  });

  tearDown(sl.reset);

  testWidgets('builds the affected reservations lazily', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CourtBlockReviewScreen(args: args)),
    );

    final last = find.text(ReservationFormats.dayAndHours(reservations.last));
    expect(last, findsNothing);

    await tester.scrollUntilVisible(
      last,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(last, findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(AppStrings.courtBlockReviewConfirm(affectedCount)),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text(AppStrings.courtBlockReviewConfirm(affectedCount)),
      findsOneWidget,
    );
  });
}
