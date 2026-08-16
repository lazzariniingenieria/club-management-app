import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<LoginCubit>().login(
            _emailController.text,
            _passwordController.text,
          );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.loginEmailRequired;
    if (!value.contains('@')) return AppStrings.loginEmailInvalidFormat;
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.loginPasswordRequired;
    if (value.length < 6) return AppStrings.loginPasswordTooShort;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextFormField(
            controller: _emailController,
            hintText: AppStrings.loginEmailHint,
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          AppTextFormField(
            controller: _passwordController,
            hintText: AppStrings.loginPasswordHint,
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleVisibility: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            validator: _validatePassword,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Implement forgot password
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(AppStrings.loginForgotPassword),
            ),
          ),
          const SizedBox(height: 32),
          BlocBuilder<LoginCubit, LoginState>(
            builder: (context, state) {
              return AppButton(
                text: AppStrings.loginSubmitButton,
                isLoading: state is LoginLoading,
                onPressed: _submitForm,
              );
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: Implement navigation to first time / registration screen
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondaryLight,
              ),
              child: const Text(AppStrings.loginFirstTimeUser),
            ),
          ),
        ],
      ),
    );
  }
}
