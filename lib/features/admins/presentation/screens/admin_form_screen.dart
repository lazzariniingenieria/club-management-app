import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/formatters/digit_layout_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../members/domain/validation/member_draft_rules.dart';
import '../../domain/entities/admin.dart';
import '../../domain/entities/admin_draft.dart';
import '../../domain/entities/admin_password_rules.dart';
import '../cubit/admin_form_cubit.dart';
import '../cubit/admin_form_state.dart';
import '../widgets/admin_account_actions.dart';
import '../widgets/linked_member_field.dart';
import '../widgets/new_password_sheet.dart';
import 'admin_form_args.dart';

class AdminFormScreen extends StatelessWidget {
  final AdminFormArgs args;

  const AdminFormScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminFormCubit>(
      create: (_) => sl<AdminFormCubit>(),
      child: AdminScaffold(
        title: args.admin == null
            ? AppStrings.adminFormCreateTitle
            : AppStrings.adminFormEditTitle,
        body: _AdminForm(args: args),
      ),
    );
  }
}

class _AdminForm extends StatefulWidget {
  final AdminFormArgs args;

  const _AdminForm({required this.args});

  @override
  State<_AdminForm> createState() => _AdminFormState();
}

class _AdminFormState extends State<_AdminForm> {
  final _formKey = GlobalKey<FormState>();
  late final AdminDraft _initialDraft = widget.args.admin == null
      ? const AdminDraft(dni: '')
      : AdminDraft.fromAdmin(widget.args.admin!);
  late final TextEditingController _dni = TextEditingController(
    text: DigitLayouts.groupedByThousands(_initialDraft.dni),
  );
  late final TextEditingController _email =
      TextEditingController(text: _initialDraft.email);
  final _password = TextEditingController();
  late int? _memberId = _initialDraft.memberId;
  bool _passwordObscured = true;

  Admin? get _admin => widget.args.admin;

  AdminDraft get _draft => AdminDraft(
        dni: DigitLayouts.digitsOf(_dni.text),
        email: _email.text,
        memberId: _memberId,
      );

  bool get _hasChanges =>
      _draft.trimmed() != _initialDraft.trimmed() || _password.text.isNotEmpty;

  @override
  void dispose() {
    _dni.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<AdminFormCubit>();
    final admin = _admin;
    if (admin == null) {
      cubit.create(_draft, _password.text);
    } else {
      cubit.update(admin.id, _draft);
    }
  }

  void _onStateChanged(BuildContext context, AdminFormState state) {
    switch (state) {
      case AdminFormSaved(:final outcome):
        showAppSnackBar(context, _outcomeMessage(outcome));
        context.pop();
      case AdminFormFailure(:final message):
        showAppSnackBar(context, message, isError: true);
      case AdminFormEditing():
      case AdminFormSubmitting():
      case AdminFormConflict():
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
      listenable: Listenable.merge([_dni, _email, _password]),
      builder: (context, form) => PopScope(
        canPop: !_hasChanges,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmDiscard();
        },
        child: form!,
      ),
      child: BlocConsumer<AdminFormCubit, AdminFormState>(
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

  List<Widget> _children(AdminFormState state) {
    final admin = _admin;

    return [
      if (state is AdminFormConflict) ...[
        const AppNotice(
          tone: AppNoticeTone.danger,
          message: AppStrings.adminFormConflict,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      _DniField(controller: _dni),
      const SizedBox(height: AppSpacing.lg),
      _EmailField(controller: _email),
      if (admin == null) ...[
        const SizedBox(height: AppSpacing.lg),
        _InitialPasswordField(
          controller: _password,
          obscured: _passwordObscured,
          onToggle: () =>
              setState(() => _passwordObscured = !_passwordObscured),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      LinkedMemberField(
        members: widget.args.members,
        selectedMemberId: _memberId,
        onSelected: (memberId) => setState(() => _memberId = memberId),
      ),
      const SizedBox(height: AppSpacing.xl),
      AppButton(
        text: admin == null
            ? AppStrings.adminFormCreate
            : AppStrings.adminFormSave,
        isLoading: state is AdminFormSubmitting,
        onPressed: _submit,
      ),
      if (admin != null) ...[
        const SizedBox(height: AppSpacing.xl),
        AdminAccountActions(
          admin: admin,
          members: widget.args.members,
          enabled: state is! AdminFormSubmitting,
          hasUnsavedChanges: () => _hasChanges,
        ),
      ],
    ];
  }
}

String _outcomeMessage(AdminFormOutcome outcome) {
  return switch (outcome) {
    AdminFormOutcome.created => AppStrings.adminFormCreated,
    AdminFormOutcome.updated => AppStrings.adminFormUpdated,
    AdminFormOutcome.deactivated => AppStrings.adminDeactivated,
    AdminFormOutcome.reactivated => AppStrings.adminReactivated,
  };
}

String? _messageFor(MemberFieldError? error) {
  return switch (error) {
    MemberFieldError.required => AppStrings.memberFormRequiredField,
    MemberFieldError.tooLong => AppStrings.memberFormTooLong,
    MemberFieldError.nonNumericDni => AppStrings.memberFormDniOnlyDigits,
    MemberFieldError.malformedEmail => AppStrings.memberFormMalformedEmail,
    null => null,
  };
}

class _DniField extends StatelessWidget {
  final TextEditingController controller;

  const _DniField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: const [
        DigitLayoutFormatter(
          layout: DigitLayouts.groupedByThousands,
          maxDigits: MemberDraftRules.maxDniLength,
        ),
      ],
      decoration: const InputDecoration(
        labelText: AppStrings.adminFormDni,
        prefixIcon: Icon(Icons.badge_outlined),
      ),
      validator: (value) => _messageFor(
        MemberDraftRules.validate(
          MemberField.dni,
          DigitLayouts.digitsOf(value ?? ''),
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;

  const _EmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: AppStrings.adminFormEmail,
        prefixIcon: Icon(Icons.mail_outline_rounded),
      ),
      validator: (value) => _messageFor(
        MemberDraftRules.validate(MemberField.email, value ?? ''),
      ),
    );
  }
}

class _InitialPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscured;
  final VoidCallback onToggle;

  const _InitialPasswordField({
    required this.controller,
    required this.obscured,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscured,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: AppStrings.adminFormPassword,
        helperText: AppStrings.adminFormPasswordHelp,
        helperMaxLines: 2,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: onToggle,
          tooltip: obscured
              ? AppStrings.passwordShowAction
              : AppStrings.passwordHideAction,
          icon: Icon(
            obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: (value) => NewPasswordSheet.messageFor(
        AdminPasswordRules.check(value ?? ''),
      ),
    );
  }
}
