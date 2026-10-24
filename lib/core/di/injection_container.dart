import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/admin/data/datasources/admin_summary_fake_data_source.dart';
import '../../features/admin/data/datasources/admin_summary_remote_data_source.dart';
import '../../features/admin/data/repositories/admin_summary_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_summary_repository.dart';
import '../../features/admin/domain/usecases/load_admin_summary_use_case.dart';
import '../../features/admin/presentation/cubit/admin_home_cubit.dart';
import '../../features/admin/presentation/cubit/admin_profile_cubit.dart';
import '../../features/admins/data/datasources/admin_fake_data_source.dart';
import '../../features/admins/data/datasources/admin_remote_data_source.dart';
import '../../features/admins/data/repositories/admin_repository_impl.dart';
import '../../features/admins/domain/repositories/admin_repository.dart';
import '../../features/admins/domain/usecases/load_admins_use_case.dart';
import '../../features/admins/domain/usecases/reset_admin_password_use_case.dart';
import '../../features/admins/domain/usecases/save_admin_use_case.dart';
import '../../features/admins/domain/usecases/set_admin_active_use_case.dart';
import '../../features/admins/domain/usecases/watch_admin_changes_use_case.dart';
import '../../features/admins/presentation/cubit/admin_form_cubit.dart';
import '../../features/admins/presentation/cubit/admins_cubit.dart';
import '../../features/auth/data/datasources/auth_fake_data_source.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_with_credentials_use_case.dart';
import '../../features/auth/domain/usecases/logout_use_case.dart';
import '../../features/auth/domain/usecases/restore_session_use_case.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/cubit/login_cubit.dart';
import '../../features/club/data/datasources/club_fake_data_source.dart';
import '../../features/club/data/datasources/club_remote_data_source.dart';
import '../../features/club/data/repositories/club_repository_impl.dart';
import '../../features/club/domain/repositories/club_repository.dart';
import '../../features/club/domain/usecases/load_club_use_case.dart';
import '../../features/club/domain/usecases/update_monthly_fee_use_case.dart';
import '../../features/family_groups/data/datasources/family_group_fake_data_source.dart';
import '../../features/family_groups/data/datasources/family_group_remote_data_source.dart';
import '../../features/family_groups/data/repositories/family_group_repository_impl.dart';
import '../../features/family_groups/domain/repositories/family_group_repository.dart';
import '../../features/family_groups/domain/usecases/build_family_group_use_case.dart';
import '../../features/family_groups/domain/usecases/join_family_group_use_case.dart';
import '../../features/family_groups/domain/usecases/leave_family_group_use_case.dart';
import '../../features/family_groups/domain/usecases/load_family_group_candidates_use_case.dart';
import '../../features/family_groups/domain/usecases/load_family_group_detail_use_case.dart';
import '../../features/family_groups/domain/usecases/load_family_group_use_case.dart';
import '../../features/family_groups/domain/usecases/rename_family_group_use_case.dart';
import '../../features/family_groups/domain/usecases/watch_family_group_changes_use_case.dart';
import '../../features/family_groups/presentation/cubit/family_group_builder_cubit.dart';
import '../../features/family_groups/presentation/cubit/family_group_cubit.dart';
import '../../features/family_groups/presentation/cubit/family_group_name_cubit.dart';
import '../../features/family_groups/presentation/cubit/family_group_picker_cubit.dart';
import '../../features/members/data/datasources/member_fake_data_source.dart';
import '../../features/members/data/datasources/member_remote_data_source.dart';
import '../../features/members/data/repositories/member_repository_impl.dart';
import '../../features/members/domain/repositories/member_repository.dart';
import '../../features/members/domain/usecases/create_member_use_case.dart';
import '../../features/members/domain/usecases/load_member_use_case.dart';
import '../../features/members/domain/usecases/load_members_use_case.dart';
import '../../features/members/domain/usecases/set_member_active_use_case.dart';
import '../../features/members/domain/usecases/update_member_use_case.dart';
import '../../features/members/domain/usecases/watch_roster_changes_use_case.dart';
import '../../features/members/presentation/cubit/member_form_cubit.dart';
import '../../features/payments/data/datasources/payment_fake_data_source.dart';
import '../../features/payments/data/datasources/payment_remote_data_source.dart';
import '../../features/payments/data/repositories/payment_repository_impl.dart';
import '../../features/payments/domain/repositories/payment_repository.dart';
import '../../features/payments/domain/usecases/load_family_payment_status_use_case.dart';
import '../../features/payments/domain/usecases/load_member_ledger_use_case.dart';
import '../../features/payments/domain/usecases/register_family_payment_use_case.dart';
import '../../features/payments/domain/usecases/register_payment_use_case.dart';
import '../../features/payments/domain/usecases/void_payment_use_case.dart';
import '../../features/payments/domain/usecases/watch_payment_changes_use_case.dart';
import '../../features/payments/presentation/cubit/admin_payments_cubit.dart';
import '../../features/payments/presentation/cubit/member_ledger_cubit.dart';
import '../../features/payments/presentation/cubit/register_payment_cubit.dart';
import '../../features/reports/data/datasources/payment_report_fake_data_source.dart';
import '../../features/reports/data/datasources/payment_report_remote_data_source.dart';
import '../../features/reports/data/repositories/payment_report_repository_impl.dart';
import '../../features/reports/domain/repositories/payment_report_repository.dart';
import '../../features/reports/domain/usecases/download_fee_receipts_use_case.dart';
import '../../features/reports/presentation/cubit/payment_report_cubit.dart';
import '../../features/reports/presentation/export/report_file_exporter.dart';
import '../config/app_environment.dart';
import '../config/app_features.dart';
import '../logging/app_logger.dart';
import '../network/api_client.dart';
import '../router/app_router.dart';
import '../session/session_expiry_notifier.dart';
import '../storage/secure_storage_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  _registerCore();
  _registerAuthDataSources();
  _registerAuthDomain();
  _registerAdminDataSources();
  _registerAdminDomain();
  _registerMemberDataSources();
  _registerMemberDomain();
  _registerPaymentDataSources();
  _registerPaymentDomain();
  _registerFamilyGroups();
  _registerClub();
  _registerAdmins();
  _registerReports();
  _registerPresentation();
}

void _registerCore() {
  sl.registerLazySingleton<AppLogger>(() => const DeveloperLogger());
  sl.registerLazySingleton<SessionExpiryNotifier>(SessionExpiryNotifier.new);

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageServiceImpl(sl()),
  );

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      dio: Dio(),
      refreshClient: Dio(),
      secureStorage: sl(),
      sessionExpiryNotifier: sl(),
      logger: sl(),
    ),
  );
}

void _registerAuthDataSources() {
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AppEnvironment.usesFakeDataSources
        ? AuthFakeDataSource()
        : AuthRemoteDataSourceImpl(sl(), sl()),
  );
}

void _registerAuthDomain() {
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      logger: sl(),
    ),
  );

  sl.registerLazySingleton(() => LoginWithCredentialsUseCase(sl()));
  sl.registerLazySingleton(() => RestoreSessionUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
}

void _registerAdminDataSources() {
  sl.registerLazySingleton<AdminSummaryRemoteDataSource>(
    () => AppEnvironment.usesFakeDataSources
        ? AdminSummaryFakeDataSource()
        : AdminSummaryRemoteDataSourceImpl(sl(), sl()),
  );
}

void _registerAdminDomain() {
  sl.registerLazySingleton<AdminSummaryRepository>(
    () => AdminSummaryRepositoryImpl(remoteDataSource: sl(), logger: sl()),
  );

  sl.registerLazySingleton(() => LoadAdminSummaryUseCase(sl()));
}

void _registerMemberDataSources() {
  sl.registerLazySingleton<MemberRemoteDataSource>(
    () => AppEnvironment.usesFakeDataSources
        ? MemberFakeDataSource()
        : MemberRemoteDataSourceImpl(sl(), sl()),
  );
}

void _registerMemberDomain() {
  sl.registerLazySingleton<MemberRepository>(
    () => MemberRepositoryImpl(remoteDataSource: sl(), logger: sl()),
  );

  sl.registerLazySingleton(() => LoadMembersUseCase(sl()));
  sl.registerLazySingleton(() => LoadMemberUseCase(sl()));
  sl.registerLazySingleton(() => CreateMemberUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMemberUseCase(sl()));
  sl.registerLazySingleton(() => SetMemberActiveUseCase(sl()));
  sl.registerLazySingleton(() => WatchRosterChangesUseCase(sl()));
}

void _registerPaymentDataSources() {
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => AppEnvironment.usesFakeDataSources
        ? _fakePaymentDataSource()
        : PaymentRemoteDataSourceImpl(sl(), sl()),
  );
}

PaymentFakeDataSource _fakePaymentDataSource() {
  final members = sl<MemberRemoteDataSource>();

  return PaymentFakeDataSource(
    members: members,
    onDelinquencyChanged:
        members is MemberFakeDataSource ? members.setDaysOverdue : null,
  );
}

void _registerPaymentDomain() {
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(remoteDataSource: sl(), logger: sl()),
  );

  sl.registerLazySingleton(
    () => LoadMemberLedgerUseCase(payments: sl(), club: sl()),
  );
  sl.registerLazySingleton(() => RegisterPaymentUseCase(sl()));
  sl.registerLazySingleton(() => LoadFamilyPaymentStatusUseCase(sl()));
  sl.registerLazySingleton(() => RegisterFamilyPaymentUseCase(sl()));
  sl.registerLazySingleton(() => VoidPaymentUseCase(sl()));
  sl.registerLazySingleton(() => WatchPaymentChangesUseCase(sl()));
}

void _registerFamilyGroups() {
  sl.registerLazySingleton<FamilyGroupRemoteDataSource>(
    () => AppEnvironment.usesFakeDataSources
        ? FamilyGroupFakeDataSource()
        : FamilyGroupRemoteDataSourceImpl(sl(), sl()),
  );
  sl.registerLazySingleton<FamilyGroupRepository>(
    () => FamilyGroupRepositoryImpl(remoteDataSource: sl(), logger: sl()),
  );

  sl.registerLazySingleton(() => LoadFamilyGroupUseCase(sl()));
  sl.registerLazySingleton(
    () => LoadFamilyGroupDetailUseCase(groups: sl(), members: sl()),
  );
  sl.registerLazySingleton(
    () => LoadFamilyGroupCandidatesUseCase(groups: sl(), members: sl()),
  );
  sl.registerLazySingleton(
    () => BuildFamilyGroupUseCase(groups: sl(), members: sl()),
  );
  sl.registerLazySingleton(() => RenameFamilyGroupUseCase(sl()));
  sl.registerLazySingleton(() => JoinFamilyGroupUseCase(sl()));
  sl.registerLazySingleton(() => LeaveFamilyGroupUseCase(sl()));
  sl.registerLazySingleton(() => WatchFamilyGroupChangesUseCase(sl()));

  sl.registerFactory(
    () => FamilyGroupNameCubit(loadGroup: sl(), watchChanges: sl()),
  );
  sl.registerFactory(
    () => FamilyGroupCubit(
      loadDetail: sl(),
      rename: sl(),
      leave: sl(),
      watchRosterChanges: sl(),
      watchGroupChanges: sl(),
    ),
  );
  sl.registerFactory(() => FamilyGroupPickerCubit(sl()));
  sl.registerFactory(
    () => FamilyGroupBuilderCubit(buildGroup: sl(), joinGroup: sl()),
  );
}

void _registerClub() {
  sl.registerLazySingleton<ClubRemoteDataSource>(
    () => AppEnvironment.usesFakeDataSources
        ? ClubFakeDataSource()
        : ClubRemoteDataSourceImpl(sl(), sl()),
  );
  sl.registerLazySingleton<ClubRepository>(
    () => ClubRepositoryImpl(remoteDataSource: sl(), logger: sl()),
  );

  sl.registerLazySingleton(() => LoadClubUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMonthlyFeeUseCase(sl()));
}

void _registerAdmins() {
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AppEnvironment.usesFakeDataSources
        ? AdminFakeDataSource()
        : AdminRemoteDataSourceImpl(sl(), sl()),
  );
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(remoteDataSource: sl(), logger: sl()),
  );

  sl.registerLazySingleton(() => ResetAdminPasswordUseCase(sl()));
  sl.registerLazySingleton(
    () => LoadAdminsUseCase(admins: sl(), members: sl()),
  );
  sl.registerLazySingleton(() => SaveAdminUseCase(sl()));
  sl.registerLazySingleton(() => SetAdminActiveUseCase(sl()));
  sl.registerLazySingleton(() => WatchAdminChangesUseCase(sl()));

  sl.registerFactory(
    () => AdminsCubit(
      loadAdmins: sl(),
      setAdminActive: sl(),
      watchChanges: sl(),
    ),
  );
  sl.registerFactory(
    () => AdminFormCubit(
      saveAdmin: sl(),
      setAdminActive: sl(),
      resetPassword: sl(),
    ),
  );
}

void _registerReports() {
  sl.registerLazySingleton<PaymentReportRemoteDataSource>(
    () => AppEnvironment.usesFakeDataSources
        ? PaymentReportFakeDataSource()
        : PaymentReportRemoteDataSourceImpl(sl(), sl()),
  );
  sl.registerLazySingleton<PaymentReportRepository>(
    () => PaymentReportRepositoryImpl(remoteDataSource: sl(), logger: sl()),
  );
  sl.registerLazySingleton(() => DownloadFeeReceiptsUseCase(sl()));
  sl.registerLazySingleton<ReportFileExporter>(
    () => const PrintingReportFileExporter(),
  );

  sl.registerFactory(
    () => PaymentReportCubit(
      downloadReceipts: sl(),
      exporter: sl(),
      logger: sl(),
    ),
  );
}

void _registerPresentation() {
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      restoreSession: sl(),
      logout: sl(),
      sessionExpiryNotifier: sl(),
    ),
  );

  sl.registerLazySingleton(AppFeatures.fromEnvironment);
  sl.registerLazySingleton<AppRouter>(
    () => AppRouter(authBloc: sl(), features: sl()),
  );

  sl.registerFactory(() => LoginCubit(sl()));
  sl.registerFactory(() => AdminHomeCubit(sl()));
  sl.registerFactory(
    () => AdminProfileCubit(
      loadClub: sl(),
      loadMember: sl(),
      updateMonthlyFee: sl(),
      resetPassword: sl(),
    ),
  );
  sl.registerFactory(
    () => AdminPaymentsCubit(
      loadMembers: sl(),
      watchRosterChanges: sl(),
      watchPaymentChanges: sl(),
    ),
  );
  sl.registerFactory(
    () => MemberLedgerCubit(
      loadLedger: sl(),
      voidPayment: sl(),
      watchRosterChanges: sl(),
      watchPaymentChanges: sl(),
    ),
  );
  sl.registerFactory(
    () => RegisterPaymentCubit(
      loadLedger: sl(),
      registerPayment: sl(),
      loadFamilyStatus: sl(),
      registerFamilyPayment: sl(),
    ),
  );
  sl.registerFactory(
    () => MemberFormCubit(
      createMember: sl(),
      updateMember: sl(),
      setMemberActive: sl(),
    ),
  );
}
