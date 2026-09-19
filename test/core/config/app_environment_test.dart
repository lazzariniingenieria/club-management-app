import 'package:club_management_app/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to the fake data sources until the API is live', () {
    expect(AppEnvironment.dataSourceMode, DataSourceMode.fake);
    expect(AppEnvironment.usesFakeDataSources, isTrue);
    expect(AppEnvironment.usesRemoteDataSources, isFalse);
  });

  test('ships no baked-in API host', () {
    expect(AppEnvironment.apiBaseUrl, isEmpty);
  });

  test('ships no baked-in club, so a misconfigured build cannot log in', () {
    expect(AppEnvironment.clubId, 0);
  });

  group('guardAgainstFakesInRelease', () {
    test('refuses to boot a release build wired to the fakes', () {
      expect(
        () => AppEnvironment.guardAgainstFakesInRelease(isReleaseBuild: true),
        throwsA(isA<StateError>()),
      );
    });

    test('lets debug builds run against the fakes', () {
      expect(
        () => AppEnvironment.guardAgainstFakesInRelease(isReleaseBuild: false),
        returnsNormally,
      );
    });
  });

  group('guardAgainstIncompleteRemoteConfig', () {
    test('refuses to boot a remote build without a base URL and a club', () {
      expect(
        () => AppEnvironment.guardAgainstIncompleteRemoteConfig(
          isRemoteBuild: true,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(contains('API_BASE_URL'), contains('CLUB_ID')),
          ),
        ),
      );
    });

    test('leaves fake builds alone', () {
      expect(
        () => AppEnvironment.guardAgainstIncompleteRemoteConfig(
          isRemoteBuild: false,
        ),
        returnsNormally,
      );
    });
  });
}
