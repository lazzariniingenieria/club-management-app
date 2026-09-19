import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:club_management_app/features/auth/domain/usecases/login_with_credentials_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginWithCredentialsUseCase useCase;
  late MockAuthRepository mockRepository;

  const testUser = User(id: 1, memberId: 3001, role: UserRole.member);
  const emptyFieldsFailure =
      Left<Failure, User>(ValidationFailure('DNI and password cannot be empty'));

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginWithCredentialsUseCase(mockRepository);
  });

  group('LoginWithCredentialsUseCase', () {
    test('returns ValidationFailure when the DNI is empty', () async {
      final result = await useCase(dni: '', password: 'password123');

      expect(result, emptyFieldsFailure);
      verifyNever(() => mockRepository.loginWithCredentials(
            dni: any(named: 'dni'),
            password: any(named: 'password'),
          ));
    });

    test('returns ValidationFailure when the password is empty', () async {
      final result = await useCase(dni: '30111222', password: '');

      expect(result, emptyFieldsFailure);
      verifyNever(() => mockRepository.loginWithCredentials(
            dni: any(named: 'dni'),
            password: any(named: 'password'),
          ));
    });

    test('returns ValidationFailure when the DNI is blank spaces', () async {
      final result = await useCase(dni: '   ', password: 'password123');

      expect(result, emptyFieldsFailure);
    });

    test('returns ValidationFailure when the password is blank spaces',
        () async {
      final result = await useCase(dni: '30111222', password: '   ');

      expect(result, emptyFieldsFailure);
      verifyNever(() => mockRepository.loginWithCredentials(
            dni: any(named: 'dni'),
            password: any(named: 'password'),
          ));
    });

    test('trims the DNI before delegating', () async {
      when(() => mockRepository.loginWithCredentials(
            dni: '30111222',
            password: 'password123',
          )).thenAnswer((_) async => const Right(testUser));

      await useCase(dni: '  30111222  ', password: 'password123');

      verify(() => mockRepository.loginWithCredentials(
            dni: '30111222',
            password: 'password123',
          )).called(1);
    });

    test('keeps the password untouched, spaces included', () async {
      when(() => mockRepository.loginWithCredentials(
            dni: '30111222',
            password: '  pass  ',
          )).thenAnswer((_) async => const Right(testUser));

      await useCase(dni: '30111222', password: '  pass  ');

      verify(() => mockRepository.loginWithCredentials(
            dni: '30111222',
            password: '  pass  ',
          )).called(1);
    });

    test('delegates to repository and returns User on success', () async {
      when(() => mockRepository.loginWithCredentials(
            dni: '30111222',
            password: 'password123',
          )).thenAnswer((_) async => const Right(testUser));

      final result = await useCase(dni: '30111222', password: 'password123');

      expect(result, const Right(testUser));
    });

    test('propagates repository Failure on invalid credentials', () async {
      when(() => mockRepository.loginWithCredentials(
                dni: any(named: 'dni'),
                password: any(named: 'password'),
              ))
          .thenAnswer(
              (_) async => const Left(AuthFailure('Invalid credentials')));

      final result = await useCase(dni: '30111222', password: 'wrongpass');

      expect(result, const Left(AuthFailure('Invalid credentials')));
    });

    test('propagates repository Failure on server error', () async {
      when(() => mockRepository.loginWithCredentials(
            dni: any(named: 'dni'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(dni: '30111222', password: 'password123');

      expect(result, const Left(ServerFailure('Server error')));
    });
  });
}
