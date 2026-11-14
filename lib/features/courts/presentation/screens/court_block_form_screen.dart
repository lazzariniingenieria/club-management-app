import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../domain/entities/clock_time.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/court_block_draft.dart';
import '../../domain/validation/court_block_rules.dart';
import '../cubit/court_block_form_cubit.dart';
import '../cubit/court_block_form_state.dart';
import '../widgets/court_date_field.dart';
import '../widgets/court_time_field.dart';
import 'court_block_review_args.dart';

class CourtBlockFormScreen extends StatelessWidget {
  final Court court;

  const CourtBlockFormScreen({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CourtBlockFormCubit>(
      create: (_) => sl<CourtBlockFormCubit>(),
      child: AdminScaffold(
        title: AppStrings.courtBlockFormTitle,
        body: _CourtBlockForm(court: court),
      ),
    );
  }
}

class _CourtBlockForm extends StatefulWidget {
  final Court court;

  const _CourtBlockForm({required this.court});

  @override
  State<_CourtBlockForm> createState() => _CourtBlockFormState();
}

class _CourtBlockFormState extends State<_CourtBlockForm> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late final DateTime _today = _dayOf(DateTime.now());
  late final DateTime _lastDay =
      DateTime(_today.year + _selectableYears, 12, 31);
  late DateTime _fromDay = _today;
  late DateTime _toDay = _today;
  late ClockTime _fromTime = widget.court.openingTime;
  late ClockTime _toTime = widget.court.closingTime;

  CourtBlockDraft get _draft => CourtBlockDraft(
        startsAt: CourtBlockDraft.at(_fromDay, _fromTime),
        endsAt: CourtBlockDraft.at(_toDay, _toTime),
        reason: _reason.text,
      );

  static const int _selectableYears = 2;

  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _setFromDay(DateTime day) {
    setState(() {
      _fromDay = day;
      if (_toDay.isBefore(day)) _toDay = day;
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<CourtBlockFormCubit>().create(widget.court.id, _draft);
  }

  void _onStateChanged(BuildContext context, CourtBlockFormState state) {
    switch (state) {
      case CourtBlockFormSaved():
        showAppSnackBar(context, AppStrings.courtBlockCreated);
        context.pop();
      case CourtBlockFormFailure(:final message):
        showAppSnackBar(context, message, isError: true);
      case CourtBlockFormNeedsReview():
        _review(state);
      case CourtBlockFormEditing():
      case CourtBlockFormSubmitting():
        break;
    }
  }

  Future<void> _review(CourtBlockFormNeedsReview state) async {
    final cubit = context.read<CourtBlockFormCubit>();
    final created = await context.push<bool>(
      AppRoutes.adminCourtBlockReview(widget.court.id),
      extra: CourtBlockReviewArgs(
        court: widget.court,
        draft: state.draft,
        impact: state.impact,
        hasChanged: state.hasChanged,
      ),
    );
    if (!mounted) return;

    if (created == true) {
      context.pop();
    } else {
      cubit.backToEditing();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CourtBlockFormCubit, CourtBlockFormState>(
      listener: _onStateChanged,
      builder: (context, state) => Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(widget.court.name, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            ..._fromFields(),
            const SizedBox(height: AppSpacing.lg),
            ..._toFields(),
            const SizedBox(height: AppSpacing.lg),
            _ReasonField(controller: _reason),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: AppStrings.courtBlockFormSave,
              isLoading: state is CourtBlockFormSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _fromFields() {
    return [
      CourtDateField(
        label: AppStrings.courtBlockFormFromDay,
        value: _fromDay,
        firstDay: _today,
        lastDay: _lastDay,
        onChanged: _setFromDay,
      ),
      const SizedBox(height: AppSpacing.lg),
      CourtTimeField(
        label: AppStrings.courtBlockFormFromTime,
        initialValue: _fromTime,
        options: CourtTimeField.openingOptions(widget.court.openingTime),
        onChanged: (time) => setState(() => _fromTime = time),
      ),
    ];
  }

  List<Widget> _toFields() {
    return [
      CourtDateField(
        label: AppStrings.courtBlockFormToDay,
        value: _toDay,
        firstDay: _fromDay,
        lastDay: _lastDay,
        onChanged: (day) => setState(() => _toDay = day),
      ),
      const SizedBox(height: AppSpacing.lg),
      CourtTimeField(
        label: AppStrings.courtBlockFormToTime,
        initialValue: _toTime,
        options: CourtTimeField.closingOptions(widget.court.closingTime),
        onChanged: (time) => setState(() => _toTime = time),
        validator: (_) => _draft.endsAfterStarts
            ? null
            : AppStrings.courtBlockFormEndsBeforeStart,
      ),
    ];
  }
}

class _ReasonField extends StatelessWidget {
  final TextEditingController controller;

  const _ReasonField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: AppStrings.courtBlockFormReason,
        helperText: AppStrings.courtBlockFormReasonHelp,
        prefixIcon: Icon(Icons.notes_rounded),
      ),
      validator: (value) => CourtBlockRules.reasonFits(value ?? '')
          ? null
          : AppStrings.memberFormTooLong,
    );
  }
}
