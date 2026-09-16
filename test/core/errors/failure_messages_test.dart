import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/errors/failure_messages.dart';
import 'package:club_management_app/core/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const failures = <Failure>[
    AuthFailure('Invalid credentials'),
    ValidationFailure('Validation failed'),
    NetworkFailure('Could not reach the server'),
    ServerFailure('Unknown server error'),
    CacheFailure('Local storage error'),
  ];

  test('every failure maps to a user-facing message', () {
    for (final failure in failures) {
      expect(failure.userMessage, isNotEmpty);
    }
  });

  test('never surfaces the backend English message', () {
    for (final failure in failures) {
      expect(failure.userMessage, isNot(failure.message));
    }
  });

  test('maps each failure to the copy its screen expects', () {
    expect(
      const AuthFailure().userMessage,
      AppStrings.loginInvalidCredentials,
    );
    expect(const ValidationFailure().userMessage, AppStrings.loginInvalidData);
    expect(const NetworkFailure().userMessage, AppStrings.loginNetworkError);
    expect(const ServerFailure().userMessage, AppStrings.loginServerError);
  });

  test('falls back to the generic message on an unmapped failure', () {
    expect(const CacheFailure().userMessage, AppStrings.loginServerError);
  });
}
