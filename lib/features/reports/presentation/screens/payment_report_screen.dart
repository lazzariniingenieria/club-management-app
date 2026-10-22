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
import '../../../payments/presentation/formatting/payment_formats.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentReportCubit, PaymentReportState>(
      builder: (context, state) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(AppStrings.reportPeriodQuestion, style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.md),
          _ModeSelector(state: state),
          const SizedBox(height: AppSpacing.lg),
          _PeriodFields(state: state),
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

class _ModeSelector extends StatelessWidget {
  final PaymentReportState state;

  const _ModeSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ReportRangeMode>(
      segments: const [
        ButtonSegment(
          value: ReportRangeMode.single,
          label: Text(AppStrings.reportModeSingle),
        ),
        ButtonSegment(
          value: ReportRangeMode.range,
          label: Text(AppStrings.reportModeRange),
        ),
      ],
      selected: {state.mode},
      onSelectionChanged: (selection) =>
          context.read<PaymentReportCubit>().selectMode(selection.single),
    );
  }
}

class _PeriodFields extends StatelessWidget {
  final PaymentReportState state;

  const _PeriodFields({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaymentReportCubit>();
    if (state.mode == ReportRangeMode.single) {
      return _MonthField(
        label: AppStrings.reportMonthLabel,
        value: state.from,
        onChanged: cubit.selectFrom,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthField(
          label: AppStrings.reportFromLabel,
          value: state.from,
          onChanged: cubit.selectFrom,
        ),
        const SizedBox(height: AppSpacing.md),
        _MonthField(
          label: AppStrings.reportToLabel,
          value: state.to,
          onChanged: cubit.selectTo,
          errorText:
              state.period.isValid ? null : AppStrings.reportInvalidRange,
        ),
      ],
    );
  }
}

class _MonthField extends StatelessWidget {
  final String label;
  final BillingMonth value;
  final ValueChanged<BillingMonth> onChanged;
  final String? errorText;

  const _MonthField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  static const int _monthsOffered = 24;

  List<BillingMonth> get _options {
    final months = <BillingMonth>[];
    var month = BillingMonth.of(DateTime.now());
    for (var index = 0; index < _monthsOffered; index++) {
      months.add(month);
      month = month.previous;
    }
    if (!months.contains(value)) months.add(value);

    return months;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<BillingMonth>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, errorText: errorText),
      items: [
        for (final month in _options)
          DropdownMenuItem(
            value: month,
            child: Text(PaymentFormats.monthTitle(month)),
          ),
      ],
      onChanged: (month) {
        if (month != null) onChanged(month);
      },
    );
  }
}

class _ReportOutcome extends StatelessWidget {
  final PaymentReportState state;

  const _ReportOutcome({required this.state});

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      ReportStatus.failed => AppNotice(
          tone: AppNoticeTone.danger,
          title: state.isOffline
              ? AppStrings.reportOfflineTitle
              : AppStrings.reportServerTitle,
          message: state.isOffline
              ? AppStrings.reportOffline
              : AppStrings.reportServer,
        ),
      ReportStatus.ready when state.hadNoCollections =>
        const AppNotice(message: AppStrings.reportEmpty),
      ReportStatus.ready => _ReadyReport(period: state.period),
      _ => const SizedBox.shrink(),
    };
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
          Text(AppStrings.reportReadyHint, style: AppTextStyles.bodyMedium),
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
