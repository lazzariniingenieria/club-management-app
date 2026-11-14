import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/recurring_slots/presentation/formatting/recurring_slot_formats.dart';
import 'package:club_management_app/features/reservations/data/datasources/reservation_fake_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

void main() {
  Finder tab(String label) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );

  Finder inDialog(String label) => find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(label),
      );

  Finder inSheet(String label) => find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(label),
      );

  Finder dropdown(int index) =>
      find.byType(DropdownButtonFormField<int>).at(index);

  Finder formScrollable() => find
      .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
      .first;

  Future<void> openRecurringSlots(WidgetTester tester) async {
    await bootApp(tester, signedInAs: UserRole.admin);
    await tester.tap(tab(AppStrings.adminTabReservations));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.recurringSlotsAction));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, int field, String option) async {
    await tester.ensureVisible(dropdown(field));
    await tester.tap(dropdown(field));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> fillActivity(
    WidgetTester tester, {
    required String description,
    required String court,
    required int weekday,
    required String start,
  }) async {
    await tester.tap(find.text(AppStrings.recurringSlotsNew));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.recurringSlotFormForActivity));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, description);
    await choose(tester, 0, court);
    await choose(tester, 1, RecurringSlotFormats.weekday(weekday));
    final chip = find.widgetWithText(ChoiceChip, start);
    await tester.scrollUntilVisible(chip, 200, scrollable: formScrollable());
    await tester.tap(chip);
    await tester.pumpAndSettle();
    final continueButton = find.text(AppStrings.reservationFormContinue);
    await tester.scrollUntilVisible(
      continueButton,
      200,
      scrollable: formScrollable(),
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
  }

  testWidgets('lists the current slots by weekday and the expired ones apart',
      (tester) async {
    await openRecurringSlots(tester);

    expect(
      find.textContaining(ReservationFakeDataSource.seededActivity),
      findsOneWidget,
    );
    expect(find.textContaining('Venció el'), findsNothing);

    await tester.tap(find.text(AppStrings.recurringSlotsExpired));
    await tester.pumpAndSettle();

    expect(find.textContaining('Venció el'), findsOneWidget);
    expect(
      find.textContaining(ReservationFakeDataSource.seededActivity),
      findsNothing,
    );
  });

  testWidgets('creates a slot for a club activity after reviewing it', (
    tester,
  ) async {
    await openRecurringSlots(tester);

    await fillActivity(
      tester,
      description: 'Escuela de pádel',
      court: 'Cancha de Pádel 1',
      weekday: DateTime.saturday,
      start: '10:00',
    );

    expect(find.text(AppStrings.recurringSlotConfirmTitle), findsOneWidget);
    expect(find.textContaining('Todos los sábados, 10:00 a 11:00'),
        findsOneWidget);
    expect(find.textContaining('Se reservan'), findsOneWidget);

    await tester.tap(find.text(AppStrings.recurringSlotConfirmAction));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.recurringSlotCreated), findsOneWidget);
    expect(find.text(AppStrings.recurringSlotsTitle), findsOneWidget);
    expect(find.textContaining('Escuela de pádel'), findsOneWidget);
  });

  testWidgets('lists the dates that clash and creates nothing', (tester) async {
    await openRecurringSlots(tester);
    final now = DateTime.now();
    final inTwoDays = DateTime(now.year, now.month, now.day + 2);

    await fillActivity(
      tester,
      description: 'Torneo interno',
      court: 'Cancha de Pádel 1',
      weekday: inTwoDays.weekday,
      start: '18:00',
    );
    await tester.tap(find.text(AppStrings.recurringSlotConfirmAction));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        AppStrings.recurringSlotClashTitle,
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(AppStrings.clashReserved, findRichText: true),
      findsOneWidget,
    );
    final create = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text(AppStrings.recurringSlotConfirmAction),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(create.onPressed, isNull);
  });

  testWidgets('deactivates a slot after confirming', (tester) async {
    await openRecurringSlots(tester);

    await tester.tap(
      find.textContaining(ReservationFakeDataSource.seededActivity),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.recurringSlotDeactivate));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(AppStrings.recurringSlotDeactivate));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.recurringSlotDeactivated), findsOneWidget);
    expect(
      find.textContaining(ReservationFakeDataSource.seededActivity),
      findsNothing,
    );

    await tester.tap(find.text(AppStrings.recurringSlotsInactive));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(ReservationFakeDataSource.seededActivity),
      findsOneWidget,
    );
  });

  testWidgets('renews an expired slot from today', (tester) async {
    await openRecurringSlots(tester);
    await tester.tap(find.text(AppStrings.recurringSlotsExpired));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Venció el'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.recurringSlotRenew));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(AppStrings.recurringSlotRenew).last);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.recurringSlotRenewed), findsOneWidget);

    await tester.tap(find.text(AppStrings.recurringSlotsCurrent));
    await tester.pumpAndSettle();

    expect(find.text('SÁBADO'), findsOneWidget);
  });
}
