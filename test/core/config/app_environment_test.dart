import 'package:club_management_app/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to the fake data sources until the API is live', () {
    expect(AppEnvironment.dataSourceMode, DataSourceMode.fake);
    expect(AppEnvironment.usesFakeDataSources, isTrue);
  });

  test('never falls back to localhost as the base URL', () {
    expect(AppEnvironment.apiBaseUrl, isNot(contains('localhost')));
    expect(AppEnvironment.apiBaseUrl, startsWith('https://'));
  });
}
