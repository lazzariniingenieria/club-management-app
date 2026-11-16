import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/recurring_slots/data/datasources/recurring_slot_fake_data_source.dart';
import 'package:club_management_app/features/recurring_slots/data/models/recurring_slot_model.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot_draft.dart';
import 'package:club_management_app/features/recurring_slots/presentation/formatting/recurring_slot_formats.dart';
import 'package:club_management_app/features/reservations/data/datasources/reservation_fake_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

class SignalLostOnCreate extends RecurringSlotFakeDataSource {
  SignalLostOnCreate() : super(latency: Duration.zero);

  bool _signalLost = false;

  @override
  Future<List<RecurringSlotModel>> fetchRecurringSlots() {
    if (_signalLost) throw NetworkException('offline');

    return super.fetchRecurringSlots();
  }

  @override
  Future<RecurringSlotModel> createRecurringSlot(RecurringSlotDraft draft) {
    _signalLost = true;
    throw ResponseTimeoutException('no answer');
  }
}

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

  Future<void> openRecurringSlots(
    WidgetTester tester, {
    RecurringSlotFakeDataSource? source,
  }) async {
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      recurringSlotSource: source,
    );
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

  testWidgets('a failed reload keeps what the admin filled in', (
    tester,
  ) async {
    await openRecurringSlots(tester, source: SignalLostOnCreate());

    await fillActivity(
      tester,
      description: 'Escuela de pádel',
      court: 'Cancha de Pádel 1',
      weekday: DateTime.saturday,
      start: '10:00',
    );
    await tester.tap(find.text(AppStrings.recurringSlotConfirmAction));
    await tester.pumpAndSettle();
    await tapBackButton(tester);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.recurringSlotsErrorTitle), findsNothing);
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -200,
      scrollable: formScrollable(),
    );
    final description = tester.widget<TextField>(find.byType(TextField).first);
    expect(description.controller?.text, 'Escuela de pádel');
    expect(find.text('Cancha de Pádel 1'), findsOneWidget);
  });

  testWidgets('warns about an overdue member and still creates the slot', (
    tester,
  ) async {
    await openRecurringSlots(tester);
    await tester.tap(find.text(AppStrings.recurringSlotsNew));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.reservationFormMemberUnset));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Juan Álvarez');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Juan Álvarez').last);
    await tester.pumpAndSettle();
    await choose(tester, 0, 'Cancha de Pádel 1');
    await choose(tester, 1, RecurringSlotFormats.weekday(DateTime.saturday));
    final chip = find.widgetWithText(ChoiceChip, '10:00');
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

    expect(
      find.textContaining('Juan Álvarez tiene', findRichText: true),
      findsOneWidget,
    );

    final confirm = find.text(AppStrings.recurringSlotConfirmAction);
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.recurringSlotCreated), findsOneWidget);
  });
}
