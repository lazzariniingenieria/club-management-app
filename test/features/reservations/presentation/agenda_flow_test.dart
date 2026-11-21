import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/reservations/data/datasources/reservation_fake_data_source.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation_draft.dart';
import 'package:club_management_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

class _TimingOutReservations extends ReservationFakeDataSource {
  _TimingOutReservations({required this.goesThrough})
      : super(latency: Duration.zero);

  final bool goesThrough;
  int _timeoutsLeft = 1;

  @override
  Future<void> createReservation(ReservationDraft draft) async {
    if (_timeoutsLeft == 0) return super.createReservation(draft);

    _timeoutsLeft--;
    if (goesThrough) await super.createReservation(draft);
    throw ResponseTimeoutException();
  }
}

void main() {
  late ReservationFakeDataSource reservations;

  Finder tab(String label) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );

  const continueLabel = AppStrings.reservationFormContinue;
  final continueButton = find.text(continueLabel);

  Finder inDialog(String label) => find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(label),
      );

  Future<void> openTomorrow(
    WidgetTester tester, {
    ReservationFakeDataSource? source,
  }) async {
    reservations = source ?? ReservationFakeDataSource(latency: Duration.zero);
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      reservationSource: reservations,
    );
    await tester.tap(tab(AppStrings.adminTabReservations));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.agendaNextDay));
    await tester.pumpAndSettle();
  }

  Future<void> reviewJuanOnTennisAtEight(WidgetTester tester) async {
    await tester.tap(find.text(AppStrings.agendaNew));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.reservationDuration(60)), findsOneWidget);
    await tester.tap(find.text(AppStrings.reservationFormMemberUnset));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Juan Álvarez');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Juan Álvarez').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancha de Tenis 1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '08:00'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      continueButton,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text(AppStrings.reservationConfirmAction));
    await tester.pumpAndSettle();
  }

  Future<void> reserveForAnotherMemberAtEight() {
    final now = DateTime.now();

    return reservations.createReservation(
      ReservationDraft(
        courtId: 2,
        memberId: ReservationFakeDataSource.seededMemberId,
        date: DateTime(now.year, now.month, now.day + 1),
        startTime: const ClockTime(8, 0),
        endTime: const ClockTime(9, 0),
      ),
    );
  }

  testWidgets('shows the reservations and blocks of the day by court', (
    tester,
  ) async {
    await openTomorrow(tester);

    expect(find.text('Cancha de Pádel 1'), findsOneWidget);
    expect(find.text('Cancha de Tenis 1'), findsOneWidget);
    expect(find.text('19:00 a 20:00'), findsOneWidget);
    expect(find.text('María Álvarez'), findsOneWidget);
    expect(find.textContaining('Bloqueada 08:00 a 12:00'), findsOneWidget);
  });

  testWidgets('cancels a reservation after confirming', (tester) async {
    await openTomorrow(tester);

    await tester.tap(find.text(AppStrings.reservationCancel));
    await tester.pumpAndSettle();
    expect(inDialog(AppStrings.backAction), findsOneWidget);
    await tester.tap(inDialog(AppStrings.reservationCancelConfirm));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.reservationCancelled), findsOneWidget);
    expect(find.text('19:00 a 20:00'), findsNothing);
  });

  testWidgets('a fixed slot date is skipped, not cancelled', (tester) async {
    await openTomorrow(tester);
    await tester.tap(find.byTooltip(AppStrings.agendaNextDay));
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.reservationActivityHolder(
        ReservationFakeDataSource.seededActivity,
      )),
      findsOneWidget,
    );
    expect(find.textContaining('· Turno fijo'), findsOneWidget);
    expect(find.text(AppStrings.reservationCancel), findsNothing);

    await tester.tap(find.text(AppStrings.reservationSkip).first);
    await tester.pumpAndSettle();
    await tester.tap(inDialog(AppStrings.reservationSkipConfirm));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.reservationSkipped), findsOneWidget);
    expect(find.text(AppStrings.reservationSkip), findsOneWidget);
  });

  testWidgets('reserves a court for a member and warns about the debt', (
    tester,
  ) async {
    await openTomorrow(tester);

    await reviewJuanOnTennisAtEight(tester);
    expect(find.textContaining('días de mora'), findsOneWidget);

    await confirm(tester);

    expect(find.text(AppStrings.reservationConfirmed), findsOneWidget);
    expect(find.text('08:00 a 09:00'), findsOneWidget);
    expect(find.text('Juan Álvarez'), findsOneWidget);
  });

  testWidgets(
    'a reservation whose confirmation timed out but went through ends as '
    'confirmed',
    (tester) async {
      await openTomorrow(
        tester,
        source: _TimingOutReservations(goesThrough: true),
      );
      await reviewJuanOnTennisAtEight(tester);

      await confirm(tester);

      expect(find.text(AppStrings.reservationConfirmed), findsOneWidget);
      expect(find.text('08:00 a 09:00'), findsOneWidget);
    },
  );

  testWidgets(
    'a reservation whose confirmation timed out without going through asks '
    'to retry and reserves once',
    (tester) async {
      await openTomorrow(
        tester,
        source: _TimingOutReservations(goesThrough: false),
      );
      await reviewJuanOnTennisAtEight(tester);

      await confirm(tester);
      expect(find.text(AppStrings.networkErrorMessage), findsOneWidget);
      expect(find.text(AppStrings.reservationSlotTaken), findsNothing);
      await confirm(tester);

      expect(find.text(AppStrings.reservationConfirmed), findsOneWidget);
      expect(find.text('08:00 a 09:00'), findsOneWidget);
    },
  );

  testWidgets('after a slot is taken meanwhile, going back shows it as '
      'occupied', (tester) async {
    await openTomorrow(tester);
    await reviewJuanOnTennisAtEight(tester);
    await tester.runAsync(reserveForAnotherMemberAtEight);

    await confirm(tester);
    expect(find.text(AppStrings.reservationSlotTaken), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final taken = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '08:00 · ${AppStrings.slotReserved}'),
    );
    expect(taken.onSelected, isNull);
    expect(
      tester.widget<AppButton>(find.widgetWithText(AppButton, continueLabel))
          .onPressed,
      isNull,
    );
  });

  testWidgets('a taken or blocked start cannot be chosen', (tester) async {
    await openTomorrow(tester);

    await tester.tap(find.text(AppStrings.agendaNew));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancha de Pádel 1').last);
    await tester.pumpAndSettle();

    final blocked = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '08:00 · ${AppStrings.slotBlocked}'),
    );
    expect(blocked.onSelected, isNull);
  });
}
