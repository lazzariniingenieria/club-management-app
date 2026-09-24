import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/admin/domain/entities/admin_summary.dart';
import 'package:club_management_app/features/admin/domain/usecases/load_admin_summary_use_case.dart';
import 'package:club_management_app/features/admin/presentation/cubit/admin_home_cubit.dart';
import 'package:club_management_app/features/admin/presentation/cubit/admin_home_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLoadAdminSummaryUseCase extends Mock
    implements LoadAdminSummaryUseCase {}

void main() {
  late MockLoadAdminSummaryUseCase useCase;
  late AdminHomeCubit cubit;

  const summary = AdminSummary(activeMembers: 230, overdueMembers: 25);

  void stub(Either<Failure, AdminSummary> result) {
    when(() => useCase()).thenAnswer((_) async => result);
  }

  setUp(() {
    useCase = MockLoadAdminSummaryUseCase();
    cubit = AdminHomeCubit(useCase);
  });

  tearDown(() => cubit.close());

  test('starts loading so the screen never opens on an empty summary', () {
    expect(cubit.state, const AdminHomeLoading());
  });

  test('emits loading then the summary', () async {
    stub(const Right(summary));

    final states = <AdminHomeState>[];
    cubit.stream.listen(states.add);

    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(states, [const AdminHomeLoading(), const AdminHomeReady(summary)]);
  });

  test('turns each failure into its Spanish message', () async {
    const cases = <(Failure, String)>[
      (NetworkFailure('Unreachable'), AppStrings.loginNetworkError),
      (ServerFailure('Boom'), AppStrings.loginServerError),
    ];

    for (final (failure, expectedMessage) in cases) {
      final scopedCubit = AdminHomeCubit(useCase);
      stub(Left(failure));

      await scopedCubit.load();

      expect(scopedCubit.state, AdminHomeFailure(expectedMessage));
      await scopedCubit.close();
    }
  });

  test('a retry after a failure reloads the summary', () async {
    stub(const Left(ServerFailure('Boom')));
    await cubit.load();

    stub(const Right(summary));
    await cubit.load();

    expect(cubit.state, const AdminHomeReady(summary));
    verify(() => useCase()).called(2);
  });

  test('a reload keeps the numbers on screen instead of the skeleton',
      () async {
    const freshSummary = AdminSummary(activeMembers: 231, overdueMembers: 24);
    stub(const Right(summary));
    await cubit.load();

    final states = <AdminHomeState>[];
    cubit.stream.listen(states.add);
    stub(const Right(freshSummary));
    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(states, [const AdminHomeReady(freshSummary)]);
  });

  test('a failed reload reports the error instead of keeping old numbers',
      () async {
    stub(const Right(summary));
    await cubit.load();

    stub(const Left(NetworkFailure('Unreachable')));
    await cubit.load();

    expect(cubit.state, const AdminHomeFailure(AppStrings.loginNetworkError));
  });
}
