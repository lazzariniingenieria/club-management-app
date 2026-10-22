import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/app_sheet_frame.dart';
import '../../domain/entities/admin_password_rules.dart';

typedef PasswordSave = Future<Failure?> Function(String newPassword);

class NewPasswordSheet extends StatefulWidget {
  final String title;
  final String notice;
  final String actionLabel;
  final PasswordSave onSave;

  const NewPasswordSheet({
    super.key,
    required this.title,
    required this.notice,
    required this.actionLabel,
    required this.onSave,
  });

  static Future<bool> show(BuildContext context, NewPasswordSheet sheet) {
    return showAppSheet<bool>(context, (_) => sheet)
        .then((saved) => saved ?? false);
  }

  static String? messageFor(PasswordProblem? problem) {
    return switch (problem) {
      PasswordProblem.tooShort => AppStrings.passwordTooShort,
      PasswordProblem.tooLong => AppStrings.passwordTooLong,
      null => null,
    };
  }

  @override
  State<NewPasswordSheet> createState() => _NewPasswordSheetState();
}

class _NewPasswordSheetState extends State<NewPasswordSheet> {
  final _password = TextEditingController();
  bool _obscured = true;
  bool _isSaving = false;
  String? _fieldError;
  Failure? _failure;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final problem = AdminPasswordRules.check(_password.text);
    setState(() => _fieldError = NewPasswordSheet.messageFor(problem));
    if (problem != null) return;

    setState(() => _isSaving = true);
    final failure = await widget.onSave(_password.text);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSaving = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: widget.title,
      children: [
        if (_failure != null) ...[
          AppNotice(
            tone: AppNoticeTone.danger,
            message: _failure is NetworkFailure
                ? AppStrings.saveFailedOffline
                : AppStrings.saveFailedServer,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _PasswordField(
          controller: _password,
          obscured: _obscured,
          enabled: !_isSaving,
          errorText: _fieldError,
          onToggle: () => setState(() => _obscured = !_obscured),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppNotice(message: widget.notice),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          text: _failure == null ? widget.actionLabel : AppStrings.retryAction,
          isLoading: _isSaving,
          onPressed: _save,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSecondaryButton(
          label: AppStrings.cancelAction,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscured;
  final bool enabled;
  final String? errorText;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.obscured,
    required this.enabled,
    required this.errorText,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      enabled: enabled,
      obscureText: obscured,
      autocorrect: false,
      enableSuggestions: false,
      maxLength: AdminPasswordRules.maxLength,
      decoration: InputDecoration(
        labelText: AppStrings.passwordNewLabel,
        helperText: AppStrings.passwordHelp,
        errorText: errorText,
        counterText: '',
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
    );
  }
}
