import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/session/session_expiry_notifier.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:club_management_app/features/auth/domain/usecases/restore_session_use_case.dart';
import 'package:club_management_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:club_management_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockRestoreSessionUseCase extends Mock implements RestoreSessionUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

void main() {
  const storedAdmin = User(
    id: '1',
    email: 'admin@club.com',
    fullName: 'Ana Gómez',
    role: UserRole.admin,
  );

  late MockRestoreSessionUseCase restoreSession;
  late MockLogoutUseCase logout;
  late SessionExpiryNotifier expiryNotifier;
  late AuthBloc authBloc;

  setUp(() {
    restoreSession = MockRestoreSessionUseCase();
    logout = MockLogoutUseCase();
    expiryNotifier = SessionExpiryNotifier();
    authBloc = AuthBloc(
      restoreSession: restoreSession,
      logout: logout,
      sessionExpiryNotifier: expiryNotifier,
    );
  });

  tearDown(() async {
    await authBloc.close();
    expiryNotifier.dispose();
  });

  Future<void> pumpSplash(WidgetTester tester, Duration restoreLatency) async {
    when(() => restoreSession()).thenAnswer(
      (_) => Future.delayed(restoreLatency, () => const Right(storedAdmin)),
    );

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const MaterialApp(home: SplashScreen()),
      ),
    );
  }

  testWidgets('shows no spinner while the session resolves quickly',
      (tester) async {
    await pumpSplash(tester, Duration.zero);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(AppStrings.splashLoading), findsNothing);

    await tester.pump(SplashScreen.progressDelay);
  });

  testWidgets('adds a spinner once the session takes longer to resolve',
      (tester) async {
    await pumpSplash(tester, const Duration(seconds: 2));

    await tester.pump(SplashScreen.progressDelay);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(AppStrings.splashLoading), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });
}
