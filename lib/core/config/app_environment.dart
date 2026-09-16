import 'package:flutter/foundation.dart';

enum DataSourceMode { fake, remote }

abstract final class AppEnvironment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://club-management-api.onrender.com/api/v1',
  );

  static const String _dataSource = String.fromEnvironment(
    'DATA_SOURCE',
    defaultValue: _fakeDataSource,
  );

  static const String _fakeDataSource = 'fake';
  static const String _remoteDataSource = 'remote';

  static DataSourceMode get dataSourceMode => switch (_dataSource) {
        _remoteDataSource => DataSourceMode.remote,
        _ => DataSourceMode.fake,
      };

  static bool get usesFakeDataSources => dataSourceMode == DataSourceMode.fake;

  static void guardAgainstFakesInRelease({bool isReleaseBuild = kReleaseMode}) {
    if (!isReleaseBuild || !usesFakeDataSources) return;

    throw StateError(
      'This release build is wired to the fake data sources, which accept '
      'seeded test credentials. Rebuild with --dart-define=DATA_SOURCE=remote.',
    );
  }
}
