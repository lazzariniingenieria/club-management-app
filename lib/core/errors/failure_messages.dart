import '../constants/app_strings.dart';
import 'failures.dart';

extension FailureUserMessage on Failure {
  String get userMessage => switch (this) {
        AuthFailure() => AppStrings.loginInvalidCredentials,
        ValidationFailure() => AppStrings.loginInvalidData,
        NetworkFailure() => AppStrings.loginNetworkError,
        _ => AppStrings.loginServerError,
      };
}
