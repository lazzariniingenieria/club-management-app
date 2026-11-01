import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../payments/domain/entities/billing_month.dart';
import '../../../payments/presentation/widgets/month_grid.dart';
import '../../domain/entities/payment_report_period.dart';
import '../cubit/payment_report_cubit.dart';
import '../cubit/payment_report_state.dart';
import '../formatting/payment_report_formats.dart';

class PaymentReportScreen extends StatelessWidget {
  const PaymentReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PaymentReportCubit>(
      create: (_) => sl<PaymentReportCubit>(),
      child: const AdminScaffold(
        title: AppStrings.reportTitle,
        body: _ReportBody(),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody();

  static bool _producedDocument(
    PaymentReportState previous,
    PaymentReportState current,
  ) =>
      previous.isGenerating && current.document != null;

  void _showReady(BuildContext context, PaymentReportState state) {
    final cubit = context.read<PaymentReportCubit>();
    final period = state.period;
    if (period == null) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _ReadySheet(period: period),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentReportCubit, PaymentReportState>(
      listenWhen: _producedDocument,
      listener: _showReady,
      builder: (context, state) => Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _PeriodGrid(state: state),
                const SizedBox(height: AppSpacing.sm),
                const AppNotice(message: AppStrings.reportScopeNote),
              ],
            ),
          ),
          _ReportFooter(state: state),
        ],
      ),
    );
  }
}

class _ReportFooter extends StatelessWidget {
  final PaymentReportState state;

  const _ReportFooter({required this.state});

  @override
  Widget build(BuildContext context) {
    final period = state.period;

    return Material(
      color: AppColors.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FooterNotice(state: state),
              Semantics(
                liveRegion: true,
                child: Text(
                  period == null
                      ? AppStrings.registerPaymentNoMonths
                      : PaymentReportFormats.periodLabel(period),
                  style: AppTextStyles.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                text: AppStrings.reportGenerate,
                isLoading: state.isGenerating,
                onPressed: state.canGenerate
                    ? context.read<PaymentReportCubit>().generate
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterNotice extends StatelessWidget {
  final PaymentReportState state;

  const _FooterNotice({required this.state});

  @override
  Widget build(BuildContext context) {
    final notice = switch (state.status) {
      ReportStatus.generating => Text(
          AppStrings.reportGenerating,
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ReportStatus.failed => _FailureNotice(state: state),
      ReportStatus.ready when state.hadNoCollections =>
        const AppNotice(message: AppStrings.reportEmpty),
      _ => null,
    };
    if (notice == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: notice,
    );
  }
}

class _PeriodGrid extends StatelessWidget {
  final PaymentReportState state;

  const _PeriodGrid({required this.state});

  MonthCellLook _lookOf(BillingMonth month) {
    if (state.includes(month)) {
      return MonthCellLook.selected(
        AppStrings.reportMonthChosen,
        isEnabled: state.canToggle(month),
      );
    }

    return state.canToggle(month)
        ? const MonthCellLook.available()
        : const MonthCellLook.unavailable();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaymentReportCubit>();
    final year = state.visibleYear;

    return MonthGrid(
      view: MonthGridYear(
        year: year,
        canGoBack: year > state.earliestYear,
        canGoForward: year < state.currentMonth.year,
      ),
      lookOf: _lookOf,
      onTap: state.isGenerating ? null : cubit.tapMonth,
      onShowYear: cubit.showYear,
    );
  }
}

class _FailureNotice extends StatelessWidget {
  final PaymentReportState state;

  const _FailureNotice({required this.state});

  (String, String) get _copy {
    if (state.timedOut) {
      return (AppStrings.reportTimeoutTitle, AppStrings.reportTimeout);
    }
    if (state.isOffline) {
      return (AppStrings.reportOfflineTitle, AppStrings.reportOffline);
    }

    return (AppStrings.reportServerTitle, AppStrings.reportServer);
  }

  @override
  Widget build(BuildContext context) {
    final (title, message) = _copy;

    return AppNotice(
      tone: AppNoticeTone.danger,
      title: title,
      message: message,
    );
  }
}

class _ReadySheet extends StatelessWidget {
  final PaymentReportPeriod period;

  const _ReadySheet({required this.period});

  Future<void> _run(BuildContext context, Future<bool> Function() action) async {
    final succeeded = await action();
    if (!succeeded && context.mounted) {
      showAppSnackBar(context, AppStrings.reportExportFailed, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaymentReportCubit>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                AppStrings.reportReadyTitle,
                style: AppTextStyles.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              PaymentReportFormats.periodLabel(period),
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _run(context, cubit.share),
              icon: const Icon(Icons.share_outlined),
              label: const Text(AppStrings.reportShare),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: AppStrings.reportPreview,
              onPressed: () => _run(context, cubit.preview),
            ),
          ],
        ),
      ),
    );
  }
}
