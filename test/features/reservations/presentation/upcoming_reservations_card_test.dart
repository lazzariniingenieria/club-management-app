import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation.dart';
import 'package:club_management_app/features/reservations/domain/entities/upcoming_reservations.dart';
import 'package:club_management_app/features/reservations/presentation/cubit/upcoming_reservations_cubit.dart';
import 'package:club_management_app/features/reservations/presentation/cubit/upcoming_reservations_state.dart';
import 'package:club_management_app/features/reservations/presentation/widgets/upcoming_reservations_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUpcomingReservationsCubit extends Mock
    implements UpcomingReservationsCubit {}

const Court court = Court(
  id: 1,
  name: 'Cancha de Pádel 1',
  openingTime: ClockTime(8, 0),
  closingTime: ClockTime(23, 0),
  isActive: true,
);

const Member marcos = Member(
  id: 7,
  firstName: 'Marcos',
  lastName: 'Gómez',
  dni: '30111222',
  status: MemberStatus.active,
  daysOverdue: 0,
);

final UpcomingReservations upcoming = UpcomingReservations(
  items: [
    UpcomingReservation(
      reservation: Reservation(
        id: 1,
        courtId: 1,
        memberId: 7,
        date: DateTime(2026, 11, 13),
        startTime: const ClockTime(18, 0),
        endTime: const ClockTime(19, 0),
      ),
      court: court,
    ),
  ],
  roster: const [marcos],
);

void main() {
  late MockUpcomingReservationsCubit cubit;
  late int openedAgenda;

  Future<void> pumpCard(WidgetTester tester, UpcomingReservationsState state) {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.load()).thenAnswer((_) async {});

    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<UpcomingReservationsCubit>.value(
            value: cubit,
            child: UpcomingReservationsCard(
              onOpenAgenda: () => openedAgenda++,
            ),
          ),
        ),
      ),
    );
  }

  setUp(() {
    cubit = MockUpcomingReservationsCubit();
    openedAgenda = 0;
  });

  testWidgets('shows nothing when the club has no courts', (tester) async {
    await pumpCard(tester, const UpcomingReservationsHidden());

    expect(
      find.text(AppStrings.upcomingReservationsTitle.toUpperCase()),
      findsNothing,
    );
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('shows a placeholder while loading', (tester) async {
    await pumpCard(tester, const UpcomingReservationsLoading());

    expect(
      find.text(AppStrings.upcomingReservationsTitle.toUpperCase()),
      findsNothing,
    );
    expect(find.text(AppStrings.upcomingReservationsErrorTitle), findsNothing);
  });

  testWidgets('a failure offers to retry', (tester) async {
    await pumpCard(
      tester,
      const UpcomingReservationsFailure(isOffline: true),
    );

    expect(find.text(AppStrings.upcomingReservationsErrorTitle), findsOne);
    expect(find.text(AppStrings.networkErrorMessage), findsOne);
    await tester.tap(find.text(AppStrings.retryAction));
    verify(() => cubit.load()).called(1);
  });

  testWidgets('lists who plays where, and opens the agenda on tap',
      (tester) async {
    await pumpCard(tester, UpcomingReservationsReady(upcoming));

    expect(find.text(marcos.fullName), findsOne);
    expect(find.text(court.name), findsOne);
    await tester.tap(find.text(court.name));
    expect(openedAgenda, 1);
  });

  testWidgets('says when nothing is left for today', (tester) async {
    await pumpCard(
      tester,
      const UpcomingReservationsReady(UpcomingReservations(items: [])),
    );

    expect(find.text(AppStrings.upcomingReservationsNoneLeft), findsOne);
  });
}
