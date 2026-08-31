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
}
