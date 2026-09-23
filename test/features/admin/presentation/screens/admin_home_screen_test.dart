import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/admin/data/datasources/admin_summary_fake_data_source.dart';
import 'package:club_management_app/features/admin/data/datasources/admin_summary_remote_data_source.dart';
import 'package:club_management_app/features/admin/data/models/admin_summary_model.dart';
import 'package:club_management_app/features/admin/presentation/screens/admin_home_screen.dart';
import 'package:club_management_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class ScriptedSummaryDataSource implements AdminSummaryRemoteDataSource {
  ScriptedSummaryDataSource(this._results);

  final List<Object> _results;
  int _calls = 0;

  @override
  Future<AdminSummaryModel> fetchSummary() async {
    final index = _calls < _results.length ? _calls : _results.length - 1;
    _calls++;

    final result = _results[index];

    if (result is AdminSummaryModel) return result;

    throw result as Exception;
  }
}

void main() {
  const summary = AdminSummaryModel(activeMembers: 230, overdueMembers: 25);

  Future<void> pumpHome(
    WidgetTester tester,
    AdminSummaryRemoteDataSource dataSource,
  ) async {
    await di.sl.reset();
    await di.init();

    di.sl.unregister<AdminSummaryRemoteDataSource>();
    di.sl.registerLazySingleton<AdminSummaryRemoteDataSource>(
      () => dataSource,
    );

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: di.sl<AuthBloc>(),
        child: const MaterialApp(home: AdminHomeScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows both counters once the summary loads', (tester) async {
    await pumpHome(tester, ScriptedSummaryDataSource([summary]));

    expect(find.text('230'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
  });

  testWidgets('labels every counter, so the colour is never the only cue', (
    tester,
  ) async {
    await pumpHome(tester, ScriptedSummaryDataSource([summary]));

    expect(
      find.text(AppStrings.adminHomeActiveMembers.toUpperCase()),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.adminHomeOverdueMembers.toUpperCase()),
      findsOneWidget,
    );
  });

  testWidgets('offers the quick access cards of the club', (tester) async {
    await pumpHome(tester, ScriptedSummaryDataSource([summary]));

    expect(find.text(AppStrings.adminHomeMembersAccess), findsOneWidget);
    expect(find.text(AppStrings.adminHomeCourtsAccess), findsOneWidget);
  });

  testWidgets('shows the skeleton first and the counters after the call', (
    tester,
  ) async {
    await di.sl.reset();
    await di.init();
    di.sl.unregister<AdminSummaryRemoteDataSource>();
    di.sl.registerLazySingleton<AdminSummaryRemoteDataSource>(
      () => AdminSummaryFakeDataSource(
        latency: const Duration(milliseconds: 50),
      ),
    );

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: di.sl<AuthBloc>(),
        child: const MaterialApp(home: AdminHomeScreen()),
      ),
    );

    expect(find.text('230'), findsNothing);

    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('230'), findsOneWidget);
  });

  testWidgets('explains a failed summary and lets the admin retry', (
    tester,
  ) async {
    await pumpHome(
      tester,
      ScriptedSummaryDataSource([NetworkException('offline'), summary]),
    );

    expect(find.text(AppStrings.adminHomeSummaryErrorTitle), findsOneWidget);
    expect(find.text(AppStrings.loginNetworkError), findsOneWidget);

    await tester.tap(find.text(AppStrings.retryAction));
    await tester.pump();

    expect(find.text('230'), findsOneWidget);
    expect(find.text(AppStrings.adminHomeSummaryErrorTitle), findsNothing);
  });

  testWidgets('keeps the quick access cards visible when the summary fails', (
    tester,
  ) async {
    await pumpHome(
      tester,
      ScriptedSummaryDataSource([NetworkException('offline')]),
    );

    expect(find.text(AppStrings.adminHomeMembersAccess), findsOneWidget);
  });
}
