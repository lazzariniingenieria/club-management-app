import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_features.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/formatters/display_formats.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/status_message_view.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../payments/presentation/formatting/payment_formats.dart';
import '../cubit/club_metrics_cubit.dart';
import '../cubit/club_metrics_state.dart';
import '../widgets/collection_chart.dart';

class ClubMetricsScreen extends StatelessWidget {
  const ClubMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClubMetricsCubit>(
      create: (_) => sl<ClubMetricsCubit>()..load(),
      child: AdminScaffold(
        title: AppStrings.metricsTitle,
        body: BlocBuilder<ClubMetricsCubit, ClubMetricsState>(
          builder: (context, state) => switch (state) {
            ClubMetricsLoading() => const _MetricsSkeleton(),
            ClubMetricsReady() => _MetricsContent(state: state),
            ClubMetricsFailure(:final isOffline) => StatusMessageView(
                icon: isOffline ? Icons.wifi_off_rounded : Icons.dns_outlined,
                title: AppStrings.metricsErrorTitle,
                message: isOffline
                    ? AppStrings.networkErrorMessage
                    : AppStrings.serverErrorMessage,
                actionLabel: AppStrings.retryAction,
                onAction: context.read<ClubMetricsCubit>().load,
              ),
          },
        ),
      ),
    );
  }
}

class _MetricsContent extends StatelessWidget {
  final ClubMetricsReady state;

  const _MetricsContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClubMetricsCubit>();

    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _MonthSwitcher(state: state),
          const SizedBox(height: AppSpacing.lg),
          _MetricTiles(state: state),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            header: true,
            child: Text(
              AppStrings.metricsChartTitle.toUpperCase(),
              style: AppTextStyles.sectionLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          CollectionChart(
            collections: state.recentCollections,
            selected: state.month,
            onSelect: cubit.showMonth,
          ),
          if (sl<AppFeatures>().feeReceipts) const _GeneratePdfButton(),
        ],
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  final ClubMetricsReady state;

  const _MonthSwitcher({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClubMetricsCubit>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: cubit.showPreviousMonth,
            tooltip: AppStrings.metricsPreviousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                PaymentFormats.monthTitle(state.month),
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium,
              ),
            ),
          ),
          IconButton(
            onPressed: state.canShowNextMonth ? cubit.showNextMonth : null,
            tooltip: AppStrings.metricsNextMonth,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _MetricTiles extends StatelessWidget {
  final ClubMetricsReady state;

  const _MetricTiles({required this.state});

  @override
  Widget build(BuildContext context) {
    final collection = state.collection;
    final previous = state.previousCollection;
    final previousMonth = PaymentFormats.monthName(state.month.previous);

    return Column(
      children: [
        _TileRow(
          first: _MetricTile(
            label: AppStrings.metricsCollected,
            value: DisplayFormats.pesos(collection.totalCents),
            change: _Change.percent(
              collection.totalCents,
              previous.totalCents,
              previousMonth,
            ),
          ),
          second: _MetricTile(
            label: AppStrings.metricsFees,
            value: '${collection.feeCount}',
            change: _Change.count(
              collection.feeCount,
              previous.feeCount,
              previousMonth,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _TileRow(
          first: _MetricTile(
            label: AppStrings.metricsNewMembers,
            value: '${state.newMembers}',
          ),
          second: _MetricTile(
            label: AppStrings.metricsOverdueToday,
            value: '${state.metrics.overdueMembers}',
          ),
        ),
      ],
    );
  }
}

class _TileRow extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _TileRow({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: first),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: second),
        ],
      ),
    );
  }
}

class _Change {
  final IconData? icon;
  final String text;

  const _Change(this.icon, this.text);

  static _Change? percent(int current, int previous, String month) {
    if (previous == 0) return null;

    final percent = ((current - previous) * 100 / previous).round();

    return _of(percent, AppStrings.metricsPercentChange(percent.abs()), month);
  }

  static _Change? count(int current, int previous, String month) {
    if (previous == 0) return null;

    final difference = current - previous;

    return _of(difference, '${difference.abs()}', month);
  }

  static _Change _of(int difference, String amount, String month) {
    if (difference == 0) return _Change(null, AppStrings.metricsSameAs(month));

    return _Change(
      difference > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
      AppStrings.metricsVersus(amount, month),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final _Change? change;

  const _MetricTile({required this.label, required this.value, this.change});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppTextStyles.titleLarge),
            ),
            if (change != null) _ChangeLine(change: change!),
          ],
        ),
      ),
    );
  }
}

class _ChangeLine extends StatelessWidget {
  final _Change change;

  const _ChangeLine({required this.change});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          if (change.icon != null) ...[
            Icon(change.icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 2),
          ],
          Flexible(
            child: Text(change.text, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _GeneratePdfButton extends StatelessWidget {
  const _GeneratePdfButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: ElevatedButton.icon(
        onPressed: () => context.push(AppRoutes.adminFeeReceipts),
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text(AppStrings.metricsGeneratePdf),
      ),
    );
  }
}

class _MetricsSkeleton extends StatelessWidget {
  const _MetricsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonBox(height: 48),
          SizedBox(height: AppSpacing.lg),
          SkeletonBox(height: 96),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(height: 96),
          SizedBox(height: AppSpacing.xl),
          SkeletonBox(height: 196),
        ],
      ),
    );
  }
}
