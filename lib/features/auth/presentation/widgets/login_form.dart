import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_form_field.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  static const int _maxDniLength = 20;

  @override
  void dispose() {
    _dniController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<LoginCubit>().login(
            _dniController.text,
            _passwordController.text,
          );
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  String? _validateDni(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.loginDniRequired;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.loginPasswordRequired;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextFormField(
              controller: _dniController,
              hintText: AppStrings.loginDniHint,
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_maxDniLength),
              ],
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              validator: _validateDni,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextFormField(
              controller: _passwordController,
              hintText: AppStrings.loginPasswordHint,
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              obscureText: _obscurePassword,
              onToggleVisibility: _togglePasswordVisibility,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitForm(),
              validator: _validatePassword,
            ),
            const SizedBox(height: AppSpacing.md),
            const _ForgotPasswordLink(),
            const SizedBox(height: AppSpacing.xl),
            BlocBuilder<LoginCubit, LoginState>(
              builder: (context, state) => AppButton(
                text: AppStrings.loginSubmitButton,
                isLoading: state is LoginLoading,
                onPressed: _submitForm,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _FirstTimeUserLink(),
          ],
        ),
      ),
    );
  }
}

class _ForgotPasswordLink extends StatelessWidget {
  const _ForgotPasswordLink();

  @override
  Widget build(BuildContext context) {
    // TODO(E11): navigate to /login/forgot once the flow exists.
    return const Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: null,
        child: Text(AppStrings.loginForgotPassword),
      ),
    );
  }
}

class _FirstTimeUserLink extends StatelessWidget {
  const _FirstTimeUserLink();

  @override
  Widget build(BuildContext context) {
    // TODO(E11): navigate to /login/activate once the flow exists.
    return Center(
      child: TextButton(
        onPressed: null,
        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
        child: const Text(AppStrings.loginFirstTimeUser),
      ),
    );
  }
}
