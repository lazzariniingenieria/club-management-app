import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/status_message_view.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../domain/entities/recurring_slot.dart';
import '../../domain/entities/recurring_slot_overview.dart';
import '../cubit/recurring_slots_cubit.dart';
import '../formatting/recurring_slot_formats.dart';
import 'recurring_slot_detail_args.dart';

class RecurringSlotsScreen extends StatelessWidget {
  const RecurringSlotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecurringSlotsCubit>(
      create: (_) => sl<RecurringSlotsCubit>()..load(),
      child: const AdminScaffold(
        title: AppStrings.recurringSlotsTitle,
        floatingActionButton: _NewRecurringSlotButton(),
        body: _RecurringSlotsBody(),
      ),
    );
  }
}

class _NewRecurringSlotButton extends StatelessWidget {
  const _NewRecurringSlotButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecurringSlotsCubit, RecurringSlotsState>(
      builder: (context, state) {
        final canCreate = state is RecurringSlotsReady &&
            state.overview.activeCourts.isNotEmpty;
        if (!canCreate) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.adminRecurringSlotCreation),
          icon: const Icon(Icons.add_rounded),
          label: const Text(AppStrings.recurringSlotsNew),
        );
      },
    );
  }
}

class _RecurringSlotsBody extends StatefulWidget {
  const _RecurringSlotsBody();

  @override
  State<_RecurringSlotsBody> createState() => _RecurringSlotsBodyState();
}

class _RecurringSlotsBodyState extends State<_RecurringSlotsBody> {
  RecurringSlotState _shown = RecurringSlotState.current;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StateChips(
          shown: _shown,
          onChanged: (state) => setState(() => _shown = state),
        ),
        Expanded(
          child: BlocBuilder<RecurringSlotsCubit, RecurringSlotsState>(
            builder: (context, state) => switch (state) {
              RecurringSlotsLoading() => const _ListSkeleton(),
              RecurringSlotsFailure(:final isOffline) => StatusMessageView(
                  icon: isOffline ? Icons.wifi_off_rounded : Icons.dns_outlined,
                  title: AppStrings.recurringSlotsErrorTitle,
                  message: isOffline
                      ? AppStrings.networkErrorMessage
                      : AppStrings.ledgerServerErrorMessage,
                  actionLabel: AppStrings.retryAction,
                  onAction: context.read<RecurringSlotsCubit>().load,
                ),
              RecurringSlotsReady(:final overview) =>
                _SlotList(overview: overview, shown: _shown),
            },
          ),
        ),
      ],
    );
  }
}

class _StateChips extends StatelessWidget {
  final RecurringSlotState shown;
  final ValueChanged<RecurringSlotState> onChanged;

  const _StateChips({required this.shown, required this.onChanged});

  static const Map<RecurringSlotState, String> _labels = {
    RecurringSlotState.current: AppStrings.recurringSlotsCurrent,
    RecurringSlotState.expired: AppStrings.recurringSlotsExpired,
    RecurringSlotState.inactive: AppStrings.recurringSlotsInactive,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (final entry in _labels.entries) ...[
            ChoiceChip(
              label: Text(entry.value),
              selected: entry.key == shown,
              onSelected: (_) => onChanged(entry.key),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SlotList extends StatelessWidget {
  final RecurringSlotOverview overview;
  final RecurringSlotState shown;

  const _SlotList({required this.overview, required this.shown});

  static const double _floatingActionClearance = 96;

  List<Widget> _rows(List<RecurringSlot> slots) {
    final rows = <Widget>[];
    int? weekday;
    for (final slot in slots) {
      if (slot.weekday != weekday) {
        weekday = slot.weekday;
        rows.add(_WeekdayHeader(weekday: slot.weekday));
      }
      rows.add(_SlotRow(slot: slot, overview: overview));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final slots = overview.inState(shown)..sort(_byWeekdayAndStart);
    if (slots.isEmpty) return _EmptyState(shown: shown);

    final rows = _rows(slots);

    return RefreshIndicator(
      onRefresh: context.read<RecurringSlotsCubit>().load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          _floatingActionClearance,
        ),
        itemCount: rows.length,
        itemBuilder: (_, index) => rows[index],
      ),
    );
  }

  static int _byWeekdayAndStart(RecurringSlot a, RecurringSlot b) {
    final byWeekday = a.weekday.compareTo(b.weekday);

    return byWeekday != 0 ? byWeekday : a.startTime.compareTo(b.startTime);
  }
}

class _WeekdayHeader extends StatelessWidget {
  final int weekday;

  const _WeekdayHeader({required this.weekday});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(
          RecurringSlotFormats.weekday(weekday).toUpperCase(),
          style: AppTextStyles.sectionLabel,
        ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final RecurringSlot slot;
  final RecurringSlotOverview overview;

  const _SlotRow({required this.slot, required this.overview});

  @override
  Widget build(BuildContext context) {
    final court = overview.courtOf(slot)?.name ?? '';
    final holder = RecurringSlotFormats.holder(slot, overview.memberOf(slot));
    final notice = RecurringSlotFormats.expiryNotice(slot, DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: () => context.push(
            AppRoutes.adminRecurringSlotDetail,
            extra: RecurringSlotDetailArgs(slot: slot, overview: overview),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _SlotRowText(
              title: '${RecurringSlotFormats.hoursOf(slot)} · $court',
              subtitle:
                  '$holder · ${RecurringSlotFormats.until(slot.validUntil)}',
              notice: notice,
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotRowText extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? notice;

  const _SlotRowText({
    required this.title,
    required this.subtitle,
    required this.notice,
  });

  @override
  Widget build(BuildContext context) {
    final notice = this.notice;

    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                Text(subtitle, style: AppTextStyles.bodyMedium),
                if (notice != null)
                  Text(
                    notice,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.dangerText,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final RecurringSlotState shown;

  const _EmptyState({required this.shown});

  @override
  Widget build(BuildContext context) {
    final title = switch (shown) {
      RecurringSlotState.current => AppStrings.recurringSlotsEmptyCurrent,
      RecurringSlotState.expired => AppStrings.recurringSlotsEmptyExpired,
      RecurringSlotState.inactive => AppStrings.recurringSlotsEmptyInactive,
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (shown == RecurringSlotState.current) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.recurringSlotsEmptyCurrentHint,
              style: AppTextStyles.bodyLargeMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          for (var row = 0; row < 4; row++) ...[
            const SkeletonBox(height: 72),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
