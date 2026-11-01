import 'dart:typed_data';

import 'package:club_management_app/core/config/app_features.dart';
import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/admin/presentation/widgets/reports_access_card.dart';
import 'package:club_management_app/features/payments/presentation/widgets/month_grid.dart';
import 'package:club_management_app/features/reports/data/datasources/payment_report_fake_data_source.dart';
import 'package:club_management_app/features/reports/data/datasources/payment_report_remote_data_source.dart';
import 'package:club_management_app/features/reports/domain/entities/fee_receipts_document.dart';
import 'package:club_management_app/features/reports/domain/entities/payment_report_period.dart';
import 'package:club_management_app/features/reports/presentation/export/report_file_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

class RecordingExporter implements ReportFileExporter {
  final shared = <String>[];

  @override
  Future<void> preview(Uint8List bytes, String fileName) async {}

  @override
  Future<void> share(Uint8List bytes, String fileName) async =>
      shared.add(fileName);
}

class SlowReportSource implements PaymentReportRemoteDataSource {
  @override
  Future<FeeReceiptsDocument?> fetchFeeReceipts(PaymentReportPeriod period) =>
      throw ResponseTimeoutException('the PDF took too long');
}

void main() {
  testWidgets('the home opens the metrics, whose PDF downloads and shares', (
    tester,
  ) async {
    await bootApp(tester, signedInAs: UserRole.admin);
    final exporter = RecordingExporter();
    di.sl.unregister<ReportFileExporter>();
    di.sl.registerLazySingleton<ReportFileExporter>(() => exporter);

    await tester.tap(find.byType(ReportsAccessCard));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(AppStrings.metricsGeneratePdf),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(AppStrings.metricsGeneratePdf));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.metricsGeneratePdf));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(AppStrings.reportGenerate));
    await tester.tap(find.text(AppStrings.reportGenerate));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.reportReadyTitle), findsOneWidget);

    await tester.ensureVisible(find.text(AppStrings.reportShare));
    await tester.tap(find.text(AppStrings.reportShare));
    await tester.pumpAndSettle();

    expect(exporter.shared, ['cuotas-cobradas-octubre-2026.pdf']);
  });

  testWidgets('the members tab no longer carries the PDF action', (
    tester,
  ) async {
    await bootApp(tester, signedInAs: UserRole.admin);
    di.sl<AppRouter>().router.go(AppRoutes.adminMembers);
    await tester.pumpAndSettle();

    expect(find.byTooltip(AppStrings.reportTitle), findsNothing);
  });

  testWidgets('the month grid is locked while the PDF is generated', (
    tester,
  ) async {
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      reportSource: PaymentReportFakeDataSource(
        latency: const Duration(seconds: 1),
      ),
    );
    di.sl<AppRouter>().router.push(AppRoutes.adminFeeReceipts);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(AppStrings.reportGenerate));
    await tester.tap(find.text(AppStrings.reportGenerate));
    await tester.pump();

    final cells = tester.widgetList<InkWell>(
      find.descendant(
        of: find.descendant(
          of: find.byType(MonthGrid),
          matching: find.byType(IntrinsicHeight),
        ),
        matching: find.byType(InkWell),
      ),
    );
    expect(cells.every((cell) => cell.onTap == null), isTrue);

    await tester.pumpAndSettle();
    expect(find.text(AppStrings.reportReadyTitle), findsOneWidget);
  });

  testWidgets('a slow server is explained, not shown as offline', (
    tester,
  ) async {
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      reportSource: SlowReportSource(),
    );
    di.sl<AppRouter>().router.push(AppRoutes.adminFeeReceipts);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.reportGenerate));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(AppStrings.reportTimeout, findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining(AppStrings.reportOffline, findRichText: true),
      findsNothing,
    );
  });

  group('while the backend has no receipts endpoint', () {
    const withoutReceipts = AppFeatures(feeReceipts: false);

    testWidgets('the metrics do not offer the PDF', (tester) async {
      await bootApp(
        tester,
        signedInAs: UserRole.admin,
        features: withoutReceipts,
      );
      di.sl<AppRouter>().router.push(AppRoutes.adminReports);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.metricsCollected), findsOneWidget);
      expect(find.text(AppStrings.metricsGeneratePdf), findsNothing);
    });

    testWidgets('a link to the PDF lands on the metrics', (tester) async {
      await bootApp(
        tester,
        signedInAs: UserRole.admin,
        features: withoutReceipts,
      );
      di.sl<AppRouter>().router.go(AppRoutes.adminFeeReceipts);
      await tester.pumpAndSettle();

      final location = di
          .sl<AppRouter>()
          .router
          .routerDelegate
          .currentConfiguration
          .last
          .matchedLocation;
      expect(location, AppRoutes.adminReports);
    });
  });

  testWidgets('the generate button stays clear of the system navigation bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(bottom: 144);
    addTearDown(tester.view.reset);
    await bootApp(tester, signedInAs: UserRole.admin);
    di.sl<AppRouter>().router.push(AppRoutes.adminFeeReceipts);
    await tester.pumpAndSettle();

    final button = tester.getRect(find.text(AppStrings.reportGenerate));
    final screenHeight = tester.view.physicalSize.height / 3;
    expect(button.bottom, lessThanOrEqualTo(screenHeight - 48));
  });

  testWidgets('a finished PDF opens its actions in a sheet', (tester) async {
    await bootApp(tester, signedInAs: UserRole.admin);
    di.sl<AppRouter>().router.push(AppRoutes.adminFeeReceipts);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.reportGenerate));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(AppStrings.reportShare),
      ),
      findsOneWidget,
    );
  });
}
