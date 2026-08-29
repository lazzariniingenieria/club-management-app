import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';

class AppTextFormField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final IconData prefixIcon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;

  const AppTextFormField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.prefixIcon,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary),
        suffixIcon: isPassword
            ? _VisibilityToggle(
                obscureText: obscureText,
                onPressed: onToggleVisibility,
              )
            : null,
      ),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool obscureText;
  final VoidCallback? onPressed;

  const _VisibilityToggle({required this.obscureText, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final label = obscureText
        ? AppStrings.passwordShowAction
        : AppStrings.passwordHideAction;

    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(
        obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.textSecondary,
      ),
    );
  }
}
