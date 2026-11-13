import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/app_environment.dart';
import 'core/di/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppEnvironment.guardAgainstFakesInRelease();
  AppEnvironment.guardAgainstIncompleteRemoteConfig();

  await di.init();

  runApp(const ClubManagementApp());
}

class ClubManagementApp extends StatelessWidget {
  const ClubManagementApp({super.key});

  static const Locale clubLocale = Locale('es', 'AR');

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: di.sl<AuthBloc>(),
      child: MaterialApp.router(
        title: 'Club Management',
        theme: AppTheme.lightTheme,
        routerConfig: di.sl<AppRouter>().router,
        debugShowCheckedModeBanner: false,
        locale: clubLocale,
        supportedLocales: const [clubLocale],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
