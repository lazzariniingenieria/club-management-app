import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.loginWelcomeTitle, style: textTheme.displayLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.loginWelcomeSubtitle,
          style: AppTextStyles.bodyLargeMuted,
        ),
      ],
    );
  }
}
