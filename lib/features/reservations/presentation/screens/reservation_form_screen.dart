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
import '../../../courts/presentation/widgets/court_date_field.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/day_agenda.dart';
import '../../domain/entities/reservation_draft.dart';
import '../../domain/entities/start_option.dart';
import '../cubit/agenda_state.dart';
import '../cubit/reservation_form_cubit.dart';
import '../formatting/reservation_formats.dart';
import '../widgets/reservation_member_field.dart';
import 'reservation_confirmation_args.dart';

class ReservationFormScreen extends StatelessWidget {
  final DateTime initialDay;

  const ReservationFormScreen({super.key, required this.initialDay});

  DateTime get _firstDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return initialDay.isBefore(today) ? today : initialDay;
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = _firstDay;

    return BlocProvider<ReservationFormCubit>(
      create: (_) => sl<ReservationFormCubit>()..showDay(firstDay),
      child: AdminScaffold(
        title: AppStrings.reservationFormTitle,
        body: _ReservationForm(initialDay: firstDay),
      ),
    );
  }
}

class _ReservationForm extends StatefulWidget {
  final DateTime initialDay;

  const _ReservationForm({required this.initialDay});

  @override
  State<_ReservationForm> createState() => _ReservationFormState();
}

class _ReservationFormState extends State<_ReservationForm> {
  static const int _selectableYears = 2;

  late final DateTime _today = _dayOf(DateTime.now());
  late final DateTime _lastDay =
      DateTime(_today.year + _selectableYears, 12, 31);
  late DateTime _day = widget.initialDay;
  Member? _member;
  int? _courtId;
  int _durationMinutes = SlotRules.durationsInMinutes.first;
  ClockTime? _start;

  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  void _setDay(DateTime day) {
    setState(() {
      _day = day;
      _start = null;
    });
    context.read<ReservationFormCubit>().showDay(day);
  }

  void _continue(DayAgenda agenda) {
    final member = _member;
    final courtAgenda = agenda.agendaOf(_courtId ?? -1);
    final start = _start;
    if (member == null || courtAgenda == null || start == null) return;

    context.push(
      AppRoutes.adminReservationConfirmation,
      extra: ReservationConfirmationArgs(
        member: member,
        court: courtAgenda.court,
        draft: ReservationDraft(
          courtId: courtAgenda.court.id,
          memberId: member.id,
          date: _day,
          startTime: start,
          endTime: SlotRules.endFor(start, _durationMinutes),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReservationFormCubit, AgendaState>(
      builder: (context, state) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CourtDateField(
            label: AppStrings.reservationFormDay,
            value: _day,
            firstDay: _today,
            lastDay: _lastDay,
            onChanged: _setDay,
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._stateDependent(state),
        ],
      ),
    );
  }

  List<Widget> _stateDependent(AgendaState state) {
    return switch (state) {
      AgendaLoading() => const <Widget>[SkeletonBox(height: 240)],
      AgendaFailure() => <Widget>[
          InlineErrorCard(
            title: AppStrings.agendaErrorTitle,
            message: AppStrings.networkErrorMessage,
            onRetry: context.read<ReservationFormCubit>().reload,
          ),
        ],
      AgendaReady(:final agenda) => _choices(agenda),
    };
  }

  List<Widget> _choices(DayAgenda agenda) {
    final courtAgenda = agenda.agendaOf(_courtId ?? -1);
    final ready = _member != null && courtAgenda != null && _start != null;

    return [
      ReservationMemberField(
        members: agenda.members,
        selected: _member,
        onSelected: (member) => setState(() => _member = member),
      ),
      const SizedBox(height: AppSpacing.lg),
      _CourtField(
        agenda: agenda,
        courtId: _courtId,
        onChanged: (courtId) => setState(() {
          _courtId = courtId;
          _start = null;
        }),
      ),
      const SizedBox(height: AppSpacing.lg),
      _DurationField(
        minutes: _durationMinutes,
        onChanged: (minutes) => setState(() {
          _durationMinutes = minutes;
          _start = null;
        }),
      ),
      if (courtAgenda != null) ...[
        const SizedBox(height: AppSpacing.lg),
        _StartChoices(
          options: _optionsFor(courtAgenda),
          selected: _start,
          onSelected: (start) => setState(() => _start = start),
        ),
      ],
      const SizedBox(height: AppSpacing.xl),
      AppButton(
        text: AppStrings.reservationFormContinue,
        onPressed: ready ? () => _continue(agenda) : null,
      ),
    ];
  }

  List<StartOption> _optionsFor(CourtAgenda courtAgenda) {
    final rules = SlotRules(
      agenda: courtAgenda,
      day: _day,
      now: DateTime.now(),
    );

    return rules.startOptions(_durationMinutes);
  }
}

class _CourtField extends StatelessWidget {
  final DayAgenda agenda;
  final int? courtId;
  final ValueChanged<int> onChanged;

  const _CourtField({
    required this.agenda,
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
        for (final courtAgenda in agenda.courts)
          DropdownMenuItem(
            value: courtAgenda.court.id,
            child: Text(courtAgenda.court.name),
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
  final List<StartOption> options;
  final ClockTime? selected;
  final ValueChanged<ClockTime> onSelected;

  const _StartChoices({
    required this.options,
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
        if (!options.any((option) => option.isAvailable))
          Text(
            AppStrings.reservationFormNoSlots,
            style: AppTextStyles.bodyLargeMuted,
          ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(ReservationFormats.startOption(option)),
                selected: option.start == selected,
                onSelected: option.isAvailable
                    ? (_) => onSelected(option.start)
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}
