import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../domain/entities/clock_time.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/court_draft.dart';
import '../../domain/validation/court_draft_rules.dart';
import '../cubit/court_form_cubit.dart';
import '../cubit/court_form_state.dart';
import '../widgets/court_status_action.dart';
import '../widgets/court_time_field.dart';

class CourtFormScreen extends StatelessWidget {
  final Court? court;

  const CourtFormScreen({super.key, this.court});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CourtFormCubit>(
      create: (_) => sl<CourtFormCubit>(),
      child: AdminScaffold(
        title: court == null
            ? AppStrings.courtFormCreateTitle
            : AppStrings.courtFormEditTitle,
        body: _CourtForm(court: court),
      ),
    );
  }
}

class _CourtForm extends StatefulWidget {
  final Court? court;

  const _CourtForm({required this.court});

  @override
  State<_CourtForm> createState() => _CourtFormState();
}

class _CourtFormState extends State<_CourtForm> {
  final _formKey = GlobalKey<FormState>();
  late final CourtDraft _initialDraft = widget.court == null
      ? const CourtDraft(name: '')
      : CourtDraft.fromCourt(widget.court!);
  late final TextEditingController _name =
      TextEditingController(text: _initialDraft.name);
  late final TextEditingController _type =
      TextEditingController(text: _initialDraft.type);
  late ClockTime _openingTime = _initialDraft.openingTime;
  late ClockTime _closingTime = _initialDraft.closingTime;

  CourtDraft get _draft => CourtDraft(
        name: _name.text,
        type: _type.text,
        openingTime: _openingTime,
        closingTime: _closingTime,
      );

  bool get _hasChanges => _draft.trimmed() != _initialDraft.trimmed();

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<CourtFormCubit>();
    final court = widget.court;
    if (court == null) {
      cubit.create(_draft);
    } else {
      cubit.update(court.id, _draft);
    }
  }

  void _onStateChanged(BuildContext context, CourtFormState state) {
    switch (state) {
      case CourtFormSaved(:final outcome):
        showAppSnackBar(context, _outcomeMessage(outcome));
        context.pop();
      case CourtFormFailure(:final message):
        showAppSnackBar(context, message, isError: true);
      case CourtFormEditing():
      case CourtFormSubmitting():
      case CourtFormConflict():
        break;
    }
  }

  Future<void> _confirmDiscard() async {
    final discarded = await ConfirmationDialog.show(
      context,
      const ConfirmationDialog(
        title: AppStrings.memberFormDiscardTitle,
        message: AppStrings.memberFormDiscardMessage,
        confirmLabel: AppStrings.memberFormDiscardAction,
      ),
    );
    if (discarded && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_name, _type]),
      builder: (context, form) => PopScope(
        canPop: !_hasChanges,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmDiscard();
        },
        child: form!,
      ),
      child: BlocConsumer<CourtFormCubit, CourtFormState>(
        listener: _onStateChanged,
        builder: (context, state) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: _children(state),
          ),
        ),
      ),
    );
  }

  List<Widget> _children(CourtFormState state) {
    final court = widget.court;

    return [
      if (state is CourtFormConflict) ...[
        const AppNotice(
          tone: AppNoticeTone.danger,
          message: AppStrings.courtFormConflict,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      _NameField(controller: _name),
      const SizedBox(height: AppSpacing.lg),
      _TypeField(controller: _type),
      const SizedBox(height: AppSpacing.lg),
      ..._hourFields(),
      const SizedBox(height: AppSpacing.xl),
      AppButton(
        text: court == null
            ? AppStrings.courtFormCreate
            : AppStrings.courtFormSave,
        isLoading: state is CourtFormSubmitting,
        onPressed: _submit,
      ),
      if (court != null) ...[
        const SizedBox(height: AppSpacing.xl),
        CourtStatusAction(
          court: court,
          enabled: state is! CourtFormSubmitting,
          hasUnsavedChanges: () => _hasChanges,
        ),
      ],
    ];
  }

  List<Widget> _hourFields() {
    return [
      CourtTimeField(
        label: AppStrings.courtFormOpeningTime,
        initialValue: _openingTime,
        options: CourtTimeField.openingOptions(_initialDraft.openingTime),
        onChanged: (time) => setState(() => _openingTime = time),
      ),
      const SizedBox(height: AppSpacing.lg),
      CourtTimeField(
        label: AppStrings.courtFormClosingTime,
        initialValue: _closingTime,
        options: CourtTimeField.closingOptions(_initialDraft.closingTime),
        onChanged: (time) => setState(() => _closingTime = time),
        validator: (_) => _draft.closesAfterOpening
            ? null
            : AppStrings.courtFormClosesBeforeOpening,
      ),
    ];
  }
}

String _outcomeMessage(CourtFormOutcome outcome) {
  return switch (outcome) {
    CourtFormOutcome.created => AppStrings.courtFormCreated,
    CourtFormOutcome.updated => AppStrings.courtFormUpdated,
    CourtFormOutcome.deactivated => AppStrings.courtDeactivated,
    CourtFormOutcome.reactivated => AppStrings.courtReactivated,
  };
}

String? _messageFor(CourtFieldError? error) {
  return switch (error) {
    CourtFieldError.required => AppStrings.memberFormRequiredField,
    CourtFieldError.tooLong => AppStrings.memberFormTooLong,
    null => null,
  };
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;

  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: AppStrings.courtFormName,
        prefixIcon: Icon(Icons.sports_tennis_rounded),
      ),
      validator: (value) => _messageFor(
        CourtDraftRules.validate(CourtField.name, value ?? ''),
      ),
    );
  }
}

class _TypeField extends StatelessWidget {
  final TextEditingController controller;

  const _TypeField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: AppStrings.courtFormType,
        helperText: AppStrings.courtFormTypeHelp,
        prefixIcon: Icon(Icons.category_outlined),
      ),
      validator: (value) => _messageFor(
        CourtDraftRules.validate(CourtField.type, value ?? ''),
      ),
    );
  }
}
