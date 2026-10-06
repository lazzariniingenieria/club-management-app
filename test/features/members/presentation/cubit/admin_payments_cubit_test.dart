import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/domain/entities/member_collection_filter.dart';
import 'package:club_management_app/features/members/domain/usecases/load_members_use_case.dart';
import 'package:club_management_app/features/members/presentation/cubit/admin_payments_cubit.dart';
import 'package:club_management_app/features/members/presentation/cubit/admin_payments_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/member_roster_data_source.dart';

class MockLoadMembersUseCase extends Mock implements LoadMembersUseCase {}

void main() {
  late MockLoadMembersUseCase useCase;
  late AdminPaymentsCubit cubit;

  final overdueMember = buildMember(
    id: 1,
    firstName: 'Juan',
    lastName: 'Zárate',
    daysOverdue: 42,
  );
  final upToDateMember = buildMember(
    id: 2,
    firstName: 'Ana',
    lastName: 'Álvarez',
  );
  final inactiveMember = buildMember(
    id: 3,
    firstName: 'Luis',
    lastName: 'Gómez',
    status: MemberStatus.inactive,
  );

  List<Member> roster() => [overdueMember, upToDateMember, inactiveMember];

  void stub(Either<Failure, List<Member>> result) {
    when(() => useCase()).thenAnswer((_) async => result);
  }

  AdminPaymentsReady readyState() => cubit.state as AdminPaymentsReady;

  setUp(() {
    useCase = MockLoadMembersUseCase();
    cubit = AdminPaymentsCubit(useCase);
  });

  tearDown(() => cubit.close());

  test('starts loading so the list never opens on an empty roster', () {
    expect(cubit.state, const AdminPaymentsLoading());
  });

  test('sorts the roster by last name ignoring accents', () async {
    stub(Right(roster()));

    await cubit.load();

    expect(
      readyState().members.map((member) => member.lastName),
      ['Álvarez', 'Gómez', 'Zárate'],
    );
  });

  test('turns a failure into its Spanish message', () async {
    stub(const Left(NetworkFailure('Unreachable')));

    await cubit.load();

    expect(
        cubit.state, const AdminPaymentsFailure(AppStrings.loginNetworkError));
  });

  group('counters', () {
    setUp(() async {
      stub(Right(roster()));
      await cubit.load();
    });

    test('all counts active and inactive members alike', () {
      expect(readyState().countFor(MemberCollectionFilter.all), 3);
    });

    test('overdue counts only the members behind on the fee', () {
      expect(readyState().countFor(MemberCollectionFilter.overdue), 1);
    });

    test('toCollect starts empty and follows the selection', () {
      expect(readyState().countFor(MemberCollectionFilter.toCollect), 0);

      cubit.toggleReportSelection(upToDateMember.id);

      expect(readyState().countFor(MemberCollectionFilter.toCollect), 1);
    });
  });

  group('report selection', () {
    setUp(() async {
      stub(Right(roster()));
      await cubit.load();
    });

    test('a second tap takes the member back out of the report', () {
      cubit.toggleReportSelection(overdueMember.id);
      cubit.toggleReportSelection(overdueMember.id);

      expect(readyState().selectedMemberIds, isEmpty);
    });

    test('toCollect lists exactly the members marked for the report', () {
      cubit.toggleReportSelection(inactiveMember.id);

      final visible = readyState()
          .visibleMembers(MemberCollectionFilter.toCollect)
          .map((member) => member.id);

      expect(visible, [inactiveMember.id]);
    });

    test('a reload keeps the selection the admin already marked', () async {
      cubit.toggleReportSelection(overdueMember.id);

      await cubit.load();

      expect(readyState().selectedMemberIds, {overdueMember.id});
    });

    test('a reload drops members that left the club', () async {
      cubit.toggleReportSelection(inactiveMember.id);
      stub(Right([overdueMember, upToDateMember]));

      await cubit.load();

      expect(readyState().selectedMemberIds, isEmpty);
    });
  });

  group('search', () {
    setUp(() async {
      stub(Right(roster()));
      await cubit.load();
    });

    test('narrows the visible members without touching the counters', () {
      cubit.search('alvarez');

      expect(
        readyState().visibleMembers(MemberCollectionFilter.all).single.id,
        upToDateMember.id,
      );
      expect(readyState().countFor(MemberCollectionFilter.all), 3);
    });

    test('combines with the active filter', () {
      cubit.search('Zárate');

      expect(
        readyState().visibleMembers(MemberCollectionFilter.overdue),
        hasLength(1),
      );
      expect(
        readyState().visibleMembers(MemberCollectionFilter.toCollect),
        isEmpty,
      );
    });

    test('clearing brings the whole roster back', () {
      cubit.search('Zárate');
      cubit.clearSearch();

      expect(readyState().hasSearchQuery, isFalse);
      expect(readyState().visibleMembers(MemberCollectionFilter.all),
          hasLength(3));
    });

    test('survives a reload so a pull to refresh keeps the query', () async {
      cubit.search('Gómez');

      await cubit.load();

      expect(readyState().searchQuery, 'Gómez');
    });
  });

  group('a failed reload', () {
    setUp(() async {
      stub(Right(roster()));
      await cubit.load();
      cubit.toggleReportSelection(overdueMember.id);
      cubit.search('Zárate');
      stub(const Left(NetworkFailure('Unreachable')));
      await cubit.load();
    });

    test('carries the roster it already had', () {
      final failure = cubit.state as AdminPaymentsFailure;

      expect(failure.message, AppStrings.loginNetworkError);
      expect(failure.previous?.members, hasLength(3));
    });

    test('does not drop the selection the admin marked by hand', () {
      final failure = cubit.state as AdminPaymentsFailure;

      expect(failure.previous?.selectedMemberIds, {overdueMember.id});
      expect(failure.previous?.searchQuery, 'Zárate');
    });

    test('a later retry comes back with that selection intact', () async {
      stub(Right(roster()));

      await cubit.load();

      expect(readyState().selectedMemberIds, {overdueMember.id});
      expect(readyState().searchQuery, 'Zárate');
    });

    test('never shows the skeleton again once there is data', () async {
      final states = <AdminPaymentsState>[];
      cubit.stream.listen(states.add);
      stub(const Left(NetworkFailure('Unreachable')));

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(states.whereType<AdminPaymentsLoading>(), isEmpty);
    });
  });

  test('a first load that fails has no roster to fall back on', () async {
    stub(const Left(NetworkFailure('Unreachable')));

    await cubit.load();

    expect((cubit.state as AdminPaymentsFailure).previous, isNull);
  });

  test('a reload keeps the rows on screen instead of the skeleton', () async {
    stub(Right(roster()));
    await cubit.load();

    final states = <AdminPaymentsState>[];
    cubit.stream.listen(states.add);
    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(states.whereType<AdminPaymentsLoading>(), isEmpty);
  });
}
