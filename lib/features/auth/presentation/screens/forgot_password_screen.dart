import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_notice.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_reset_rounded,
                size: 48,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                header: true,
                child: Text(
                  AppStrings.forgotPasswordTitle,
                  style: AppTextStyles.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.forgotPasswordNoEmail,
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.forgotPasswordAskAdmin,
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppNotice(message: AppStrings.forgotPasswordMainAccount),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: () => _back(context),
                child: const Text(AppStrings.forgotPasswordBack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
