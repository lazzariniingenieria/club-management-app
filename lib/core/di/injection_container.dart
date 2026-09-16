import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

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
import '../config/app_environment.dart';
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

void _registerPresentation() {
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      restoreSession: sl(),
      logout: sl(),
      sessionExpiryNotifier: sl(),
    ),
  );

  sl.registerLazySingleton<AppRouter>(() => AppRouter(sl()));

  sl.registerFactory(() => LoginCubit(sl()));
}
