import 'dart:typed_data';

import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/reports/data/datasources/payment_report_fake_data_source.dart';
import 'package:club_management_app/features/reports/data/datasources/payment_report_remote_data_source.dart';
import 'package:club_management_app/features/reports/domain/entities/fee_receipts_document.dart';
import 'package:club_management_app/features/reports/domain/entities/payment_report_period.dart';
import 'package:club_management_app/features/reports/presentation/cubit/payment_report_state.dart';
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
  testWidgets('Pagos opens the report, which downloads and shares the PDF', (
    tester,
  ) async {
    await bootApp(tester, signedInAs: UserRole.admin);
    final exporter = RecordingExporter();
    di.sl.unregister<ReportFileExporter>();
    di.sl.registerLazySingleton<ReportFileExporter>(() => exporter);

    di.sl<AppRouter>().router.go(AppRoutes.adminPayments);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.reportTitle));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.reportGenerate));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.reportReadyTitle), findsOneWidget);

    await tester.ensureVisible(find.text(AppStrings.reportShare));
    await tester.tap(find.text(AppStrings.reportShare));
    await tester.pumpAndSettle();

    expect(exporter.shared, hasLength(1));
    expect(exporter.shared.single, startsWith('cuotas-cobradas-'));
  });

  testWidgets('the period cannot change while the PDF is generated', (
    tester,
  ) async {
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      reportSource: PaymentReportFakeDataSource(
        latency: const Duration(seconds: 1),
      ),
    );
    di.sl<AppRouter>().router.push(AppRoutes.adminPaymentReport);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.reportGenerate));
    await tester.pump();

    final modes = tester.widget<SegmentedButton<ReportRangeMode>>(
      find.byType(SegmentedButton<ReportRangeMode>),
    );
    final month = tester.widget<DropdownButton<BillingMonth>>(
      find.byType(DropdownButton<BillingMonth>),
    );
    expect(modes.onSelectionChanged, isNull);
    expect(month.onChanged, isNull);

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
    di.sl<AppRouter>().router.push(AppRoutes.adminPaymentReport);
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
}
