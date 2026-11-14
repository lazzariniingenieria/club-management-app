import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/inline_error_card.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../courts/domain/entities/clock_time.dart';
import '../../../courts/domain/entities/court.dart';
import '../../../courts/presentation/formatting/court_formats.dart';
import '../../../members/domain/entities/member.dart';
import '../../../reservations/domain/entities/start_option.dart';
import '../../../reservations/presentation/widgets/reservation_member_field.dart';
import '../../domain/entities/recurring_slot_draft.dart';
import '../../domain/entities/recurring_slot_overview.dart';
import '../../domain/entities/recurring_slot_starts.dart';
import '../../domain/entities/recurring_slot_validity.dart';
import '../cubit/recurring_slots_cubit.dart';
import '../formatting/recurring_slot_formats.dart';
import '../widgets/validity_field.dart';
import 'recurring_slot_confirmation_args.dart';

class RecurringSlotFormScreen extends StatelessWidget {
  const RecurringSlotFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecurringSlotsCubit>(
      create: (_) => sl<RecurringSlotsCubit>()..load(),
      child: AdminScaffold(
        title: AppStrings.recurringSlotFormTitle,
        body: BlocBuilder<RecurringSlotsCubit, RecurringSlotsState>(
          builder: (context, state) => switch (state) {
            RecurringSlotsLoading() => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SkeletonBox(height: 320),
              ),
            RecurringSlotsFailure() => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: InlineErrorCard(
                  title: AppStrings.recurringSlotsErrorTitle,
                  message: AppStrings.networkErrorMessage,
                  onRetry: context.read<RecurringSlotsCubit>().load,
                ),
              ),
            RecurringSlotsReady(:final overview) =>
              _RecurringSlotForm(overview: overview),
          },
        ),
      ),
    );
  }
}

enum _HolderKind { member, activity }

class _RecurringSlotForm extends StatefulWidget {
  final RecurringSlotOverview overview;

  const _RecurringSlotForm({required this.overview});

  @override
  State<_RecurringSlotForm> createState() => _RecurringSlotFormState();
}

class _RecurringSlotFormState extends State<_RecurringSlotForm> {
  late final DateTime _today = _dayOf(DateTime.now());
  final _description = TextEditingController();
  _HolderKind _holderKind = _HolderKind.member;
  Member? _member;
  int? _courtId;
  int? _weekday;
  int _durationMinutes = SlotRules.defaultDurationMinutes;
  ClockTime? _start;
  late RecurringSlotValidity _validity =
      RecurringSlotValidity.preset(_today, ValidityPreset.suggested);

  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void initState() {
    super.initState();
    _description.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Court? get _court {
    for (final court in widget.overview.activeCourts) {
      if (court.id == _courtId) return court;
    }

    return null;
  }

  RecurringSlotDraft? get _draft {
    final court = _court;
    final weekday = _weekday;
    final start = _start;
    if (court == null || weekday == null || start == null) return null;

    final draft = RecurringSlotDraft(
      courtId: court.id,
      memberId: _holderKind == _HolderKind.member ? _member?.id : null,
      description:
          _holderKind == _HolderKind.activity ? _description.text : null,
      weekday: weekday,
      startTime: start,
      endTime: SlotRules.endFor(start, _durationMinutes),
      validity: _validity,
    );

    return draft.isValid ? draft : null;
  }

  Future<void> _continue(RecurringSlotDraft draft) async {
    final created = await context.push<bool>(
      AppRoutes.adminRecurringSlotConfirmation,
      extra: RecurringSlotConfirmationArgs(
        draft: draft,
        court: _court!,
        member: _holderKind == _HolderKind.member ? _member : null,
      ),
    );
    if (created == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final dates = draft?.dates(DateTime.now()) ?? const <DateTime>[];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ..._holderFields(),
        const SizedBox(height: AppSpacing.lg),
        ..._whenFields(),
        const SizedBox(height: AppSpacing.lg),
        ValidityField(
          value: _validity,
          firstDay: _today,
          onChanged: (validity) => setState(() => _validity = validity),
        ),
        if (draft != null) ...[
          const SizedBox(height: AppSpacing.md),
          _DatesSummary(draft: draft, dates: dates),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          text: AppStrings.reservationFormContinue,
          onPressed:
              draft != null && dates.isNotEmpty ? () => _continue(draft) : null,
        ),
      ],
    );
  }

  List<Widget> _holderFields() {
    return [
      _HolderKindToggle(
        value: _holderKind,
        onChanged: (kind) => setState(() => _holderKind = kind),
      ),
      const SizedBox(height: AppSpacing.lg),
      if (_holderKind == _HolderKind.member)
        ReservationMemberField(
          members: widget.overview.members,
          selected: _member,
          onSelected: (member) => setState(() => _member = member),
        )
      else
        TextField(
          controller: _description,
          maxLength: RecurringSlotDraft.maxDescriptionLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: AppStrings.recurringSlotFormDescription,
            helperText: AppStrings.recurringSlotFormDescriptionHelp,
            prefixIcon: Icon(Icons.groups_outlined),
          ),
        ),
    ];
  }

  List<Widget> _whenFields() {
    final court = _court;

    return [
      _CourtField(
        courts: widget.overview.activeCourts,
        courtId: _courtId,
        onChanged: (courtId) => setState(() {
          _courtId = courtId;
          _start = null;
        }),
      ),
      const SizedBox(height: AppSpacing.lg),
      _WeekdayField(
        weekday: _weekday,
        onChanged: (weekday) => setState(() => _weekday = weekday),
      ),
      const SizedBox(height: AppSpacing.lg),
      _DurationField(
        minutes: _durationMinutes,
        onChanged: (minutes) => setState(() {
          _durationMinutes = minutes;
          _start = null;
        }),
      ),
      if (court != null) ...[
        const SizedBox(height: AppSpacing.lg),
        _StartChoices(
          starts: RecurringSlotStarts.of(court, _durationMinutes),
          selected: _start,
          onSelected: (start) => setState(() => _start = start),
        ),
      ],
    ];
  }
}

class _HolderKindToggle extends StatelessWidget {
  final _HolderKind value;
  final ValueChanged<_HolderKind> onChanged;

  const _HolderKindToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_HolderKind>(
      segments: const [
        ButtonSegment(
          value: _HolderKind.member,
          label: Text(AppStrings.recurringSlotFormForMember),
          icon: Icon(Icons.person_outline_rounded),
        ),
        ButtonSegment(
          value: _HolderKind.activity,
          label: Text(AppStrings.recurringSlotFormForActivity),
          icon: Icon(Icons.groups_outlined),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}

class _CourtField extends StatelessWidget {
  final List<Court> courts;
  final int? courtId;
  final ValueChanged<int> onChanged;

  const _CourtField({
    required this.courts,
    required this.courtId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: courtId,
      decoration: const InputDecoration(
        labelText: AppStrings.reservationFormCourt,
        prefixIcon: Icon(Icons.sports_tennis_rounded),
      ),
      items: [
        for (final court in courts)
          DropdownMenuItem(value: court.id, child: Text(court.name)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _WeekdayField extends StatelessWidget {
  final int? weekday;
  final ValueChanged<int> onChanged;

  const _WeekdayField({required this.weekday, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: weekday,
      hint: const Text(AppStrings.recurringSlotFormWeekdayUnset),
      decoration: const InputDecoration(
        labelText: AppStrings.recurringSlotFormWeekday,
        prefixIcon: Icon(Icons.event_repeat_rounded),
      ),
      items: [
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          DropdownMenuItem(
            value: day,
            child: Text(RecurringSlotFormats.weekday(day)),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _DurationField extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;

  const _DurationField({required this.minutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: minutes,
      decoration: const InputDecoration(
        labelText: AppStrings.reservationFormDuration,
        prefixIcon: Icon(Icons.timelapse_rounded),
      ),
      items: [
        for (final option in SlotRules.durationsInMinutes)
          DropdownMenuItem(
            value: option,
            child: Text(AppStrings.reservationDuration(option)),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _StartChoices extends StatelessWidget {
  final List<ClockTime> starts;
  final ClockTime? selected;
  final ValueChanged<ClockTime> onSelected;

  const _StartChoices({
    required this.starts,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.reservationFormStart, style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final start in starts)
              ChoiceChip(
                label: Text(CourtFormats.time(start)),
                selected: start == selected,
                onSelected: (_) => onSelected(start),
              ),
          ],
        ),
      ],
    );
  }
}

class _DatesSummary extends StatelessWidget {
  final RecurringSlotDraft draft;
  final List<DateTime> dates;

  const _DatesSummary({required this.draft, required this.dates});

  @override
  Widget build(BuildContext context) {
    final text = dates.isEmpty
        ? AppStrings.recurringSlotFormNoDates
        : RecurringSlotFormats.datesSummary(
            draft.weekday,
            dates,
            RecurringSlotValidity(from: dates.first, until: dates.last),
          );

    return Semantics(
      liveRegion: true,
      child: Text(text, style: AppTextStyles.labelLarge),
    );
  }
}
