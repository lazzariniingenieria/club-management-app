import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

enum PaymentUnavailableKind { offline, server, missing, inactive }

class PaymentUnavailableView extends StatelessWidget {
  final PaymentUnavailableKind kind;
  final VoidCallback? onRetry;

  const PaymentUnavailableView({super.key, required this.kind, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - AppSpacing.xl * 2)
                .clamp(0, double.infinity),
          ),
          child: Center(
            child: _UnavailableMessage(kind: kind, onRetry: onRetry),
          ),
        ),
      ),
    );
  }
}

class _UnavailableMessage extends StatelessWidget {
  final PaymentUnavailableKind kind;
  final VoidCallback? onRetry;

  const _UnavailableMessage({required this.kind, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final copy = _UnavailableCopy.of(kind);

    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(copy.icon, size: 40, color: copy.iconColor),
          const SizedBox(height: AppSpacing.md),
          Text(
            copy.title,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            copy.message,
            style: AppTextStyles.bodyLargeMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          _action(context),
        ],
      ),
    );
  }

  Widget _action(BuildContext context) {
    if (kind == PaymentUnavailableKind.inactive) {
      return ElevatedButton(
        onPressed: () => _leave(context),
        child: const Text(AppStrings.backAction),
      );
    }
    if (kind == PaymentUnavailableKind.missing || onRetry == null) {
      return ElevatedButton(
        onPressed: () => context.go(AppRoutes.adminPayments),
        child: const Text(AppStrings.ledgerMissingAction),
      );
    }

    return ElevatedButton(
      onPressed: onRetry,
      child: const Text(AppStrings.retryAction),
    );
  }
}

void _leave(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.adminPayments);
  }
}

class _UnavailableCopy {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;

  const _UnavailableCopy(this.title, this.message, this.icon, this.iconColor);

  static _UnavailableCopy of(PaymentUnavailableKind kind) {
    return switch (kind) {
      PaymentUnavailableKind.offline => const _UnavailableCopy(
          AppStrings.ledgerOfflineTitle,
          AppStrings.ledgerOfflineMessage,
          Icons.wifi_off_rounded,
          AppColors.dangerText,
        ),
      PaymentUnavailableKind.server => const _UnavailableCopy(
          AppStrings.ledgerServerErrorTitle,
          AppStrings.ledgerServerErrorMessage,
          Icons.dns_outlined,
          AppColors.dangerText,
        ),
      PaymentUnavailableKind.inactive => const _UnavailableCopy(
          AppStrings.registerPaymentInactiveTitle,
          AppStrings.ledgerInactiveHint,
          Icons.block_rounded,
          AppColors.textSecondary,
        ),
      PaymentUnavailableKind.missing => const _UnavailableCopy(
          AppStrings.ledgerMissingTitle,
          AppStrings.ledgerMissingMessage,
          Icons.person_search_outlined,
          AppColors.textSecondary,
        ),
    };
  }
}
