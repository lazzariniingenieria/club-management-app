import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/auth/domain/usecases/login_with_credentials_use_case.dart';
import 'package:club_management_app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:club_management_app/features/auth/presentation/cubit/login_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginUseCase extends Mock implements LoginWithCredentialsUseCase {}

void main() {
  late MockLoginUseCase useCase;
  late LoginCubit cubit;

  const admin = User(id: 12, memberId: null, role: UserRole.admin);

  void stub(Either<Failure, User> result) {
    when(() => useCase(
          dni: any(named: 'dni'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => result);
  }

  setUp(() {
    useCase = MockLoginUseCase();
    cubit = LoginCubit(useCase);
  });

  tearDown(() => cubit.close());

  test('emits loading then success', () async {
    stub(const Right(admin));

    final states = <LoginState>[];
    cubit.stream.listen(states.add);

    await cubit.login('30111222', 's3cr3t123');
    await Future<void>.delayed(Duration.zero);

    expect(states, [const LoginLoading(), const LoginSuccess(admin)]);
  });

  test('turns each failure into its Spanish message', () async {
    const cases = <(Failure, String)>[
      (AuthFailure('Invalid credentials'), AppStrings.loginInvalidCredentials),
      (ValidationFailure('Validation failed'), AppStrings.loginInvalidData),
      (NetworkFailure('Unreachable'), AppStrings.loginNetworkError),
      (ServerFailure('Boom'), AppStrings.loginServerError),
    ];

    for (final (failure, expectedMessage) in cases) {
      final scopedCubit = LoginCubit(useCase);
      stub(Left(failure));

      await scopedCubit.login('30111222', 's3cr3t123');

      expect(scopedCubit.state, LoginFailure(expectedMessage));
      await scopedCubit.close();
    }
  });

  test('never emits the English message the backend sent', () async {
    stub(const Left(ServerFailure('Invalid dni or password')));

    await cubit.login('30111222', 's3cr3t123');

    final state = cubit.state as LoginFailure;
    expect(state.message, isNot(contains('Invalid dni or password')));
  });

  test('forwards the typed credentials untouched to the use case', () async {
    stub(const Right(admin));

    await cubit.login('  30111222  ', ' pass ');

    verify(() => useCase(dni: '  30111222  ', password: ' pass ')).called(1);
  });
}
