import 'package:flutter/foundation.dart';

enum DataSourceMode { fake, remote }

abstract final class AppEnvironment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const int clubId = int.fromEnvironment('CLUB_ID', defaultValue: 0);

  static const String _dataSource = String.fromEnvironment(
    'DATA_SOURCE',
    defaultValue: _fakeDataSource,
  );

  static const String _fakeDataSource = 'fake';
  static const String _remoteDataSource = 'remote';

  static const DataSourceMode dataSourceMode = _dataSource == _remoteDataSource
      ? DataSourceMode.remote
      : DataSourceMode.fake;

  static const bool usesFakeDataSources = dataSourceMode == DataSourceMode.fake;

  static const bool usesRemoteDataSources = !usesFakeDataSources;

  static void guardAgainstFakesInRelease({bool isReleaseBuild = kReleaseMode}) {
    if (!isReleaseBuild || !usesFakeDataSources) return;

    throw StateError(
      'This release build is wired to the fake data sources, which accept '
      'seeded test credentials. Rebuild with --dart-define=DATA_SOURCE=remote.',
    );
  }

  static void guardAgainstIncompleteRemoteConfig({
    bool isRemoteBuild = usesRemoteDataSources,
  }) {
    if (!isRemoteBuild) return;

    final missing = <String>[
      if (apiBaseUrl.isEmpty) 'API_BASE_URL',
      if (clubId <= 0) 'CLUB_ID',
    ];
    if (missing.isEmpty) return;

    throw StateError(
      'This build targets the remote backend but ${missing.join(' and ')} '
      'is missing. Rebuild with --dart-define=API_BASE_URL=https://<host>/api '
      'and --dart-define=CLUB_ID=<id>.',
    );
  }
}
