import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/features/admins/data/datasources/admin_remote_data_source.dart';
import 'package:club_management_app/features/admins/data/repositories/admin_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRemoteDataSource extends Mock implements AdminRemoteDataSource {}

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  late MockAdminRemoteDataSource remote;
  late AdminRepositoryImpl repository;
  late int changes;

  setUp(() {
    remote = MockAdminRemoteDataSource();
    repository =
        AdminRepositoryImpl(remoteDataSource: remote, logger: MockAppLogger());
    changes = 0;
    repository.adminChanges.listen((_) => changes++);
  });

  void deactivationThrows(Object error) {
    when(() => remote.setAdminActive(3, isActive: false)).thenThrow(error);
  }

  test('a promoted member announces a change in the admins', () async {
    when(() => remote.promoteMember(2)).thenAnswer((_) async {});

    await repository.promoteMember(2);
    await pumpEventQueue();

    expect(changes, 1);
  });

  test('a timed out deactivation may have changed the admins', () async {
    deactivationThrows(ResponseTimeoutException());

    await repository.setAdminActive(3, isActive: false);
    await pumpEventQueue();

    expect(changes, 1);
  });

  test('a deactivation that never left the device changes nothing', () async {
    deactivationThrows(NetworkException('offline'));

    await repository.setAdminActive(3, isActive: false);
    await pumpEventQueue();

    expect(changes, 0);
  });
}
