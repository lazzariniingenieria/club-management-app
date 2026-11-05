import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/status_message_view.dart';

enum PaymentUnavailableKind { offline, server, missing, inactive }

class PaymentUnavailableView extends StatelessWidget {
  final PaymentUnavailableKind kind;
  final VoidCallback? onRetry;

  const PaymentUnavailableView({super.key, required this.kind, this.onRetry});

  bool get _canRetry =>
      onRetry != null &&
      kind != PaymentUnavailableKind.missing &&
      kind != PaymentUnavailableKind.inactive;

  String get _actionLabel {
    if (kind == PaymentUnavailableKind.inactive) return AppStrings.backAction;

    return _canRetry ? AppStrings.retryAction : AppStrings.ledgerMissingAction;
  }

  void _act(BuildContext context) {
    if (kind == PaymentUnavailableKind.inactive) return _leave(context);
    if (_canRetry) return onRetry!();

    context.go(AppRoutes.adminMembers);
  }

  @override
  Widget build(BuildContext context) {
    final copy = _UnavailableCopy.of(kind);

    return StatusMessageView(
      icon: copy.icon,
      title: copy.title,
      message: copy.message,
      isError: copy.isError,
      actionLabel: _actionLabel,
      onAction: () => _act(context),
    );
  }
}

void _leave(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.adminMembers);
  }
}

class _UnavailableCopy {
  final String title;
  final String message;
  final IconData icon;
  final bool isError;

  const _UnavailableCopy(this.title, this.message, this.icon, this.isError);

  static _UnavailableCopy of(PaymentUnavailableKind kind) {
    return switch (kind) {
      PaymentUnavailableKind.offline => const _UnavailableCopy(
          AppStrings.ledgerOfflineTitle,
          AppStrings.ledgerOfflineMessage,
          Icons.wifi_off_rounded,
          true,
        ),
      PaymentUnavailableKind.server => const _UnavailableCopy(
          AppStrings.ledgerServerErrorTitle,
          AppStrings.ledgerServerErrorMessage,
          Icons.dns_outlined,
          true,
        ),
      PaymentUnavailableKind.inactive => const _UnavailableCopy(
          AppStrings.registerPaymentInactiveTitle,
          AppStrings.ledgerInactiveHint,
          Icons.block_rounded,
          false,
        ),
      PaymentUnavailableKind.missing => const _UnavailableCopy(
          AppStrings.ledgerMissingTitle,
          AppStrings.ledgerMissingMessage,
          Icons.person_search_outlined,
          false,
        ),
    };
  }
}
