import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/reservations/data/datasources/reservation_fake_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

void main() {
  late ReservationFakeDataSource reservations;

  Finder tab(String label) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );

  Finder inDialog(String label) => find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(label),
      );

  Future<void> openTomorrow(WidgetTester tester) async {
    reservations = ReservationFakeDataSource(latency: Duration.zero);
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

  testWidgets('reserves a court for a member and warns about the debt', (
    tester,
  ) async {
    await openTomorrow(tester);

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
    final next = find.text(AppStrings.reservationFormContinue);
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();

    expect(find.textContaining('días de mora'), findsOneWidget);

    await tester.tap(find.text(AppStrings.reservationConfirmAction));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.reservationConfirmed), findsOneWidget);
    expect(find.text('08:00 a 09:00'), findsOneWidget);
    expect(find.text('Juan Álvarez'), findsOneWidget);
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
