import 'package:club_management_app/core/config/app_features.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/storage/secure_storage_service.dart';
import 'package:club_management_app/features/admin/data/datasources/admin_summary_fake_data_source.dart';
import 'package:club_management_app/features/admin/data/datasources/admin_summary_remote_data_source.dart';
import 'package:club_management_app/features/admins/data/datasources/admin_fake_data_source.dart';
import 'package:club_management_app/features/admins/data/datasources/admin_remote_data_source.dart';
import 'package:club_management_app/features/club/data/datasources/club_fake_data_source.dart';
import 'package:club_management_app/features/club/data/datasources/club_remote_data_source.dart';
import 'package:club_management_app/features/auth/data/datasources/auth_fake_data_source.dart';
import 'package:club_management_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/family_groups/data/datasources/family_group_fake_data_source.dart';
import 'package:club_management_app/features/family_groups/data/datasources/family_group_remote_data_source.dart';
import 'package:club_management_app/features/members/data/datasources/member_fake_data_source.dart';
import 'package:club_management_app/features/members/data/datasources/member_remote_data_source.dart';
import 'package:club_management_app/features/payments/data/datasources/payment_fake_data_source.dart';
import 'package:club_management_app/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:club_management_app/features/reports/data/datasources/payment_report_fake_data_source.dart';
import 'package:club_management_app/features/reports/data/datasources/payment_report_remote_data_source.dart';
import 'package:club_management_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'in_memory_secure_storage.dart';

Future<InMemorySecureStorage> bootApp(
  WidgetTester tester, {
  UserRole? signedInAs,
  AdminSummaryRemoteDataSource? adminSummarySource,
  MemberRemoteDataSource? memberSource,
  PaymentRemoteDataSource? paymentSource,
  FamilyGroupRemoteDataSource? familyGroupSource,
  ClubRemoteDataSource? clubSource,
  AdminRemoteDataSource? adminSource,
  PaymentReportRemoteDataSource? reportSource,
  AppFeatures? features,
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

  di.sl.unregister<AdminSummaryRemoteDataSource>();
  di.sl.registerLazySingleton<AdminSummaryRemoteDataSource>(
    () =>
        adminSummarySource ??
        AdminSummaryFakeDataSource(latency: Duration.zero),
  );

  di.sl.unregister<MemberRemoteDataSource>();
  di.sl.registerLazySingleton<MemberRemoteDataSource>(
    () => memberSource ?? MemberFakeDataSource(latency: Duration.zero),
  );

  di.sl.unregister<PaymentRemoteDataSource>();
  di.sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => paymentSource ?? _instantPaymentSource(),
  );

  di.sl.unregister<FamilyGroupRemoteDataSource>();
  di.sl.registerLazySingleton<FamilyGroupRemoteDataSource>(
    () =>
        familyGroupSource ?? FamilyGroupFakeDataSource(latency: Duration.zero),
  );

  di.sl.unregister<ClubRemoteDataSource>();
  di.sl.registerLazySingleton<ClubRemoteDataSource>(
    () => clubSource ?? ClubFakeDataSource(latency: Duration.zero),
  );

  di.sl.unregister<AdminRemoteDataSource>();
  di.sl.registerLazySingleton<AdminRemoteDataSource>(
    () => adminSource ?? AdminFakeDataSource(latency: Duration.zero),
  );

  di.sl.unregister<PaymentReportRemoteDataSource>();
  di.sl.registerLazySingleton<PaymentReportRemoteDataSource>(
    () => reportSource ?? PaymentReportFakeDataSource(latency: Duration.zero),
  );

  if (features != null) {
    di.sl.unregister<AppFeatures>();
    di.sl.registerLazySingleton<AppFeatures>(() => features);
  }

  await tester.pumpWidget(const ClubManagementApp());
  await settleSession(tester);

  return storage;
}

PaymentFakeDataSource _instantPaymentSource() {
  final members = di.sl<MemberRemoteDataSource>();

  return PaymentFakeDataSource(
    members: members,
    latency: Duration.zero,
    onDelinquencyChanged:
        members is MemberFakeDataSource ? members.setDaysOverdue : null,
  );
}

Future<void> settleSession(WidgetTester tester) async {
  for (var frame = 0; frame < 5; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
