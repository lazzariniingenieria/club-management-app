import 'exceptions.dart';
import 'failures.dart';

Failure failureFromException(Object error) {
  return switch (error) {
    UnauthorizedException() =>
      AuthFailure(error.message ?? 'Invalid credentials'),
    ValidationException() =>
      ValidationFailure(error.message ?? 'The request was rejected'),
    NetworkException() =>
      NetworkFailure(error.message ?? 'No internet connection'),
    ServerException() => ServerFailure(error.message ?? 'Server error'),
    CacheException() => CacheFailure(error.message ?? 'Local storage error'),
    _ => const ServerFailure('An unexpected error occurred'),
  };
}
