import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/app_text_form_field.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/member_draft.dart';
import '../../domain/validation/member_draft_rules.dart';
import '../cubit/member_form_cubit.dart';
import '../cubit/member_form_state.dart';
import 'member_status_action.dart';

class MemberForm extends StatefulWidget {
  final Member? member;

  const MemberForm({super.key, this.member});

  @override
  State<MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<MemberForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <MemberField, TextEditingController>{};
  final _touchedFields = <MemberField>{};

  late final MemberDraft _initialDraft;
  String? _takenDniError;

  bool get _isEdition => widget.member != null;

  MemberDraft get _draft => MemberDraft(
        firstName: _textOf(MemberField.firstName),
        lastName: _textOf(MemberField.lastName),
        dni: _textOf(MemberField.dni),
        phone: _textOf(MemberField.phone),
        email: _textOf(MemberField.email),
      );

  bool get _hasChanges => _draft.trimmed() != _initialDraft.trimmed();

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    _initialDraft = member == null
        ? const MemberDraft(firstName: '', lastName: '', dni: '')
        : MemberDraft.fromMember(member);

    for (final field in MemberField.values) {
      _controllers[field] = TextEditingController(text: _initialValueOf(field));
    }
    _controllers[MemberField.dni]!.addListener(_clearTakenDniError);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _initialValueOf(MemberField field) {
    return switch (field) {
      MemberField.firstName => _initialDraft.firstName,
      MemberField.lastName => _initialDraft.lastName,
      MemberField.dni => _initialDraft.dni,
      MemberField.phone => _initialDraft.phone,
      MemberField.email => _initialDraft.email,
    };
  }

  String _textOf(MemberField field) => _controllers[field]!.text;

  void _clearTakenDniError() {
    if (_takenDniError == null) return;

    setState(() => _takenDniError = null);
  }

  void _markTouched(MemberField field, bool hasFocus) {
    if (hasFocus || _touchedFields.contains(field)) return;

    setState(() => _touchedFields.add(field));
  }

  String? _validate(MemberField field, String? value) {
    if (field == MemberField.dni && _takenDniError != null) {
      return _takenDniError;
    }
    final error = MemberDraftRules.validate(field, value ?? '');

    return error == null ? null : _messageFor(error);
  }

  void _submit() {
    setState(() => _touchedFields.addAll(MemberField.values));
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<MemberFormCubit>().save(_draft, memberId: widget.member?.id);
  }

  Future<void> _confirmDiscard() async {
    final discarded = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const _DiscardChangesDialog(),
    );

    if ((discarded ?? false) && mounted) context.pop();
  }

  void _onPopInvoked(bool didPop, Object? result) {
    if (didPop) return;
    if (!_hasChanges) {
      context.pop();
      return;
    }

    _confirmDiscard();
  }

  void _onFormStateChanged(BuildContext context, MemberFormState state) {
    switch (state) {
      case MemberFormSaved(:final outcome):
        showAppSnackBar(context, _outcomeMessage(outcome));
        context.pop(true);
      case MemberFormDuplicatedDni():
        setState(() => _takenDniError = AppStrings.memberFormDniTaken);
        _formKey.currentState?.validate();
      case MemberFormFailure(:final message):
        showAppSnackBar(context, message, isError: true);
      case MemberFormEditing():
      case MemberFormSubmitting():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: BlocConsumer<MemberFormCubit, MemberFormState>(
        listener: _onFormStateChanged,
        builder: (context, state) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final field in MemberField.values) _fieldFor(field),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                text: _isEdition
                    ? AppStrings.memberFormSaveEdition
                    : AppStrings.memberFormSaveCreation,
                isLoading: state is MemberFormSubmitting,
                onPressed: _submit,
              ),
              if (widget.member != null) ...[
                const SizedBox(height: AppSpacing.xl),
                MemberStatusAction(member: widget.member!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldFor(MemberField field) {
    final style = _MemberFieldStyle.of(field);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Focus(
        onFocusChange: (hasFocus) => _markTouched(field, hasFocus),
        child: AppTextFormField(
          controller: _controllers[field]!,
          hintText: style.hintText,
          prefixIcon: style.icon,
          keyboardType: style.keyboardType,
          textCapitalization: style.textCapitalization,
          inputFormatters: [LengthLimitingTextInputFormatter(style.maxLength)],
          textInputAction: field == MemberField.email
              ? TextInputAction.done
              : TextInputAction.next,
          autovalidateMode: _touchedFields.contains(field)
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          validator: (value) => _validate(field, value),
        ),
      ),
    );
  }
}

String _outcomeMessage(MemberFormOutcome outcome) {
  return switch (outcome) {
    MemberFormOutcome.created => AppStrings.memberFormCreated,
    MemberFormOutcome.updated => AppStrings.memberFormUpdated,
    MemberFormOutcome.deactivated => AppStrings.memberDeactivated,
    MemberFormOutcome.reactivated => AppStrings.memberReactivated,
  };
}

String _messageFor(MemberFieldError error) {
  return switch (error) {
    MemberFieldError.required => AppStrings.memberFormRequiredField,
    MemberFieldError.tooLong => AppStrings.memberFormTooLong,
    MemberFieldError.nonNumericDni => AppStrings.memberFormDniOnlyDigits,
    MemberFieldError.malformedEmail => AppStrings.memberFormMalformedEmail,
  };
}

class _MemberFieldStyle {
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLength;

  const _MemberFieldStyle({
    required this.hintText,
    required this.icon,
    required this.keyboardType,
    required this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  static _MemberFieldStyle of(MemberField field) {
    return switch (field) {
      MemberField.firstName => const _MemberFieldStyle(
          hintText: AppStrings.memberFormFirstName,
          icon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          maxLength: MemberDraftRules.maxNameLength,
        ),
      MemberField.lastName => const _MemberFieldStyle(
          hintText: AppStrings.memberFormLastName,
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          maxLength: MemberDraftRules.maxNameLength,
        ),
      MemberField.dni => const _MemberFieldStyle(
          hintText: AppStrings.memberFormDni,
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          maxLength: MemberDraftRules.maxDniLength,
        ),
      MemberField.phone => const _MemberFieldStyle(
          hintText: AppStrings.memberFormPhone,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          maxLength: MemberDraftRules.maxPhoneLength,
        ),
      MemberField.email => const _MemberFieldStyle(
          hintText: AppStrings.memberFormEmail,
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          maxLength: MemberDraftRules.maxEmailLength,
        ),
    };
  }
}

class _DiscardChangesDialog extends StatelessWidget {
  const _DiscardChangesDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.memberFormDiscardTitle),
      content: const Text(AppStrings.memberFormDiscardMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.memberFormKeepEditingAction),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(AppStrings.memberFormDiscardAction),
        ),
      ],
    );
  }
}
