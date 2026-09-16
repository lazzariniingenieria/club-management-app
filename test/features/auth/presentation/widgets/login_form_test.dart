import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/auth/domain/usecases/login_with_credentials_use_case.dart';
import 'package:club_management_app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:club_management_app/features/auth/presentation/widgets/login_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginUseCase extends Mock implements LoginWithCredentialsUseCase {}

void main() {
  late MockLoginUseCase useCase;

  const admin = User(id: 12, memberId: null, role: UserRole.admin);

  Future<void> pumpForm(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider(
            create: (_) => LoginCubit(useCase),
            child: const LoginForm(),
          ),
        ),
      ),
    );
  }

  Finder dniField() => find.byType(TextFormField).first;
  Finder passwordField() => find.byType(TextFormField).last;

  setUp(() {
    useCase = MockLoginUseCase();
    when(() => useCase(
          dni: any(named: 'dni'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Right(admin));
  });

  testWidgets('asks for a DNI, not an email', (tester) async {
    await pumpForm(tester);

    expect(find.text(AppStrings.loginDniHint), findsOneWidget);
  });

  testWidgets('rejects an empty DNI', (tester) async {
    await pumpForm(tester);

    await tester.enterText(passwordField(), 's3cr3t123');
    await tester.tap(find.text(AppStrings.loginSubmitButton));
    await tester.pump();

    expect(find.text(AppStrings.loginDniRequired), findsOneWidget);
    verifyNever(() => useCase(
          dni: any(named: 'dni'),
          password: any(named: 'password'),
        ));
  });

  testWidgets('rejects a DNI of only spaces', (tester) async {
    await pumpForm(tester);

    await tester.enterText(dniField(), '    ');
    await tester.enterText(passwordField(), 's3cr3t123');
    await tester.tap(find.text(AppStrings.loginSubmitButton));
    await tester.pump();

    expect(find.text(AppStrings.loginDniRequired), findsOneWidget);
  });

  testWidgets('rejects an empty password', (tester) async {
    await pumpForm(tester);

    await tester.enterText(dniField(), '30111222');
    await tester.tap(find.text(AppStrings.loginSubmitButton));
    await tester.pump();

    expect(find.text(AppStrings.loginPasswordRequired), findsOneWidget);
  });

  testWidgets('rejects a password of only spaces, which the API rejects too',
      (tester) async {
    await pumpForm(tester);

    await tester.enterText(dniField(), '30111222');
    await tester.enterText(passwordField(), '   ');
    await tester.tap(find.text(AppStrings.loginSubmitButton));
    await tester.pump();

    expect(find.text(AppStrings.loginPasswordRequired), findsOneWidget);
    verifyNever(() => useCase(
          dni: any(named: 'dni'),
          password: any(named: 'password'),
        ));
  });

  testWidgets('submits a DNI the backend would accept', (tester) async {
    await pumpForm(tester);

    await tester.enterText(dniField(), '30111222');
    await tester.enterText(passwordField(), 's3cr3t123');
    await tester.tap(find.text(AppStrings.loginSubmitButton));
    await tester.pump();

    verify(() => useCase(dni: '30111222', password: 's3cr3t123')).called(1);
  });

  testWidgets('caps the DNI at the 20 characters the API allows',
      (tester) async {
    await pumpForm(tester);

    await tester.enterText(dniField(), '1' * 30);
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text.length, 20);
  });

  testWidgets('accepts a short password, since login is not a signup',
      (tester) async {
    await pumpForm(tester);

    await tester.enterText(dniField(), '30111222');
    await tester.enterText(passwordField(), 'abc');
    await tester.tap(find.text(AppStrings.loginSubmitButton));
    await tester.pump();

    verify(() => useCase(dni: '30111222', password: 'abc')).called(1);
  });
}
