import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/reservations/data/datasources/reservation_fake_data_source.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

void main() {
  const tennisCourtId = 2;
  late ReservationFakeDataSource reservations;
  late DateTime today;

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> reserveTennisToday(WidgetTester tester, int hour) async {
    await tester.runAsync(
      () => reservations.createReservation(
        ReservationDraft(
          courtId: tennisCourtId,
          memberId: 1,
          date: today,
          startTime: ClockTime(hour, 0),
          endTime: ClockTime(hour + 1, 0),
        ),
      ),
    );
  }

  Future<void> blockTennisToday(WidgetTester tester) async {
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    reservations = ReservationFakeDataSource(
      latency: Duration.zero,
      clock: () => today,
    );
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      reservationSource: reservations,
    );
    await reserveTennisToday(tester, 21);
    di.sl<AppRouter>().router.go(AppRoutes.adminProfile);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(AppStrings.adminCourtsTitle));
    await tester.tap(find.text('Cancha de Tenis 1'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(AppStrings.courtBlocksAction));
    await tester.tap(find.text(AppStrings.courtBlocksNew));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(AppStrings.courtBlockFormSave));
  }

  testWidgets('lists the reservation it steps on and cancels it', (
    tester,
  ) async {
    await blockTennisToday(tester);

    expect(find.text(AppStrings.courtBlockReviewTitle), findsOneWidget);
    expect(find.textContaining('21:00 a 22:00'), findsOneWidget);
    expect(
      find.textContaining(
        AppStrings.courtBlockReviewWarning(1),
        findRichText: true,
      ),
      findsOneWidget,
    );

    await tapVisible(tester, find.text(AppStrings.courtBlockReviewConfirm(1)));

    expect(find.text(AppStrings.courtBlockCreated), findsOneWidget);
    expect(find.text(AppStrings.courtBlocksTitle), findsOneWidget);
    final left = await tester.runAsync(
      () => reservations.fetchReservations(today),
    );
    expect(left, isEmpty);
  });

  testWidgets('a reservation made meanwhile is shown before blocking', (
    tester,
  ) async {
    await blockTennisToday(tester);
    await reserveTennisToday(tester, 19);

    await tapVisible(tester, find.text(AppStrings.courtBlockReviewConfirm(1)));

    expect(
      find.textContaining(
        AppStrings.courtBlockReviewChanged,
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.textContaining('19:00 a 20:00'), findsOneWidget);
    expect(find.text(AppStrings.courtBlockReviewConfirm(2)), findsOneWidget);
    final kept = await tester.runAsync(
      () => reservations.fetchReservations(today),
    );
    expect(kept, hasLength(2));
  });

  testWidgets('going back from the review leaves the form as it was', (
    tester,
  ) async {
    await blockTennisToday(tester);

    di.sl<AppRouter>().router.pop();
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.courtBlockFormTitle), findsOneWidget);
    final save = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text(AppStrings.courtBlockFormSave),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(save.onPressed, isNotNull);
  });
}
