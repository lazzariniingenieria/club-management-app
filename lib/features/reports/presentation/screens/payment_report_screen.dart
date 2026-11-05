import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
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

class _ReportBody extends StatefulWidget {
  const _ReportBody();

  @override
  State<_ReportBody> createState() => _ReportBodyState();
}

class _ReportBodyState extends State<_ReportBody> {
  static const Duration _scrollDuration = Duration(milliseconds: 300);

  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static bool _finishedGenerating(
    PaymentReportState previous,
    PaymentReportState current,
  ) =>
      previous.isGenerating && !current.isGenerating;

  void _revealOutcome() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;

      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: _scrollDuration,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentReportCubit, PaymentReportState>(
      listenWhen: _finishedGenerating,
      listener: (_, __) => _revealOutcome(),
      builder: (context, state) => ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(AppStrings.reportPeriodQuestion, style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.md),
          _PeriodGrid(state: state),
          _PeriodSummary(period: state.period),
          const SizedBox(height: AppSpacing.md),
          const AppNotice(message: AppStrings.reportScopeNote),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: AppStrings.reportGenerate,
            isLoading: state.status == ReportStatus.generating,
            onPressed: state.canGenerate
                ? context.read<PaymentReportCubit>().generate
                : null,
          ),
          if (state.status == ReportStatus.generating) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.reportGenerating,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _ReportOutcome(state: state),
        ],
      ),
    );
  }
}

class _PeriodGrid extends StatelessWidget {
  final PaymentReportState state;

  const _PeriodGrid({required this.state});

  MonthCellLook _lookOf(BillingMonth month) {
    if (!state.isOffered(month)) return const MonthCellLook.unavailable();
    if (state.includes(month)) {
      return const MonthCellLook.selected(AppStrings.reportMonthChosen);
    }

    return const MonthCellLook.available();
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

class _PeriodSummary extends StatelessWidget {
  final PaymentReportPeriod period;

  const _PeriodSummary({required this.period});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        PaymentReportFormats.periodLabel(period),
        style: AppTextStyles.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ReportOutcome extends StatelessWidget {
  final PaymentReportState state;

  const _ReportOutcome({required this.state});

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      ReportStatus.failed => _FailureNotice(state: state),
      ReportStatus.ready when state.hadNoCollections =>
        const AppNotice(message: AppStrings.reportEmpty),
      ReportStatus.ready => _ReadyReport(period: state.period),
      _ => const SizedBox.shrink(),
    };
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

class _ReadyReport extends StatelessWidget {
  final PaymentReportPeriod period;

  const _ReadyReport({required this.period});

  Future<void> _run(BuildContext context, Future<bool> Function() action) async {
    final succeeded = await action();
    if (!succeeded && context.mounted) {
      showAppSnackBar(context, AppStrings.reportExportFailed, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaymentReportCubit>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              AppStrings.reportReadyTitle,
              style: AppTextStyles.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            PaymentReportFormats.periodLabel(period),
            style: AppTextStyles.bodyMedium,
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
    );
  }
}
