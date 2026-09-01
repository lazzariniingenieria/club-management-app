import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class SessionExpiredNotice extends StatelessWidget {
  const SessionExpiredNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final reason = state is AuthUnauthenticated ? state.reason : null;
        if (reason == null || reason == SignedOutReason.signedOut) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: _SignedOutBanner(reason: reason),
        );
      },
    );
  }
}

class _SignedOutBanner extends StatelessWidget {
  final SignedOutReason reason;

  const _SignedOutBanner({required this.reason});

  String get _title => switch (reason) {
        SignedOutReason.sessionUnverified =>
          AppStrings.loginSessionUnverifiedTitle,
        _ => AppStrings.loginSessionExpiredTitle,
      };

  String get _message => switch (reason) {
        SignedOutReason.sessionUnverified =>
          AppStrings.loginSessionUnverifiedMessage,
        _ => AppStrings.loginSessionExpiredMessage,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.dangerSurface,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.dangerText),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.dangerText),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(_message, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
