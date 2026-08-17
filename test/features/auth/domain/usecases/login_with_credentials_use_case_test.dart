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

  const testUser = User(
    id: 'usr_001',
    email: 'test@club.com',
    fullName: 'Test User',
    role: UserRole.member,
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginWithCredentialsUseCase(mockRepository);
  });

  group('LoginWithCredentialsUseCase', () {
    test('returns AuthFailure when email is empty', () async {
      final result = await useCase(email: '', password: 'password123');

      expect(result, const Left(AuthFailure('Email and password cannot be empty')));
      verifyNever(() => mockRepository.loginWithCredentials(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    test('returns AuthFailure when password is empty', () async {
      final result = await useCase(email: 'test@club.com', password: '');

      expect(result, const Left(AuthFailure('Email and password cannot be empty')));
      verifyNever(() => mockRepository.loginWithCredentials(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    test('returns AuthFailure when both fields are blank spaces', () async {
      final result = await useCase(email: '   ', password: '   ');

      expect(result, const Left(AuthFailure('Email and password cannot be empty')));
    });

    test('delegates to repository and returns User on success', () async {
      when(() => mockRepository.loginWithCredentials(
            email: 'test@club.com',
            password: 'password123',
          )).thenAnswer((_) async => const Right(testUser));

      final result = await useCase(email: 'test@club.com', password: 'password123');

      expect(result, const Right(testUser));
      verify(() => mockRepository.loginWithCredentials(
            email: 'test@club.com',
            password: 'password123',
          )).called(1);
    });

    test('propagates repository Failure on invalid credentials', () async {
      when(() => mockRepository.loginWithCredentials(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Left(AuthFailure('Invalid credentials')));

      final result = await useCase(email: 'test@club.com', password: 'wrongpass');

      expect(result, const Left(AuthFailure('Invalid credentials')));
    });

    test('propagates repository Failure on server error', () async {
      when(() => mockRepository.loginWithCredentials(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(email: 'test@club.com', password: 'password123');

      expect(result, const Left(ServerFailure('Server error')));
    });
  });
}
