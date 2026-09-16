import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/storage/secure_storage_service.dart';
import 'package:club_management_app/features/auth/data/datasources/auth_fake_data_source.dart';
import 'package:club_management_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'in_memory_secure_storage.dart';

Future<InMemorySecureStorage> bootApp(
  WidgetTester tester, {
  UserRole? signedInAs,
}) async {
  final storage = InMemorySecureStorage();
  if (signedInAs != null) storage.seedSession(signedInAs);

  await di.sl.reset();
  await di.init();

  di.sl.unregister<SecureStorageService>();
  di.sl.registerLazySingleton<SecureStorageService>(() => storage);

  di.sl.unregister<AuthRemoteDataSource>();
  di.sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthFakeDataSource(latency: Duration.zero),
  );

  await tester.pumpWidget(const ClubManagementApp());
  await settleSession(tester);

  return storage;
}

Future<void> settleSession(WidgetTester tester) async {
  for (var frame = 0; frame < 5; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
