import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/formatters/display_formats.dart';
import '../../../../shared/widgets/summary_table.dart';
import '../../domain/entities/member_ledger.dart';
import '../../domain/entities/payment.dart';
import '../formatting/payment_formats.dart';
import 'payment_history_tile.dart';

class PaymentDetailSheet extends StatelessWidget {
  final Payment payment;
  final MemberLedger ledger;

  const PaymentDetailSheet({
    super.key,
    required this.payment,
    required this.ledger,
  });

  static Future<bool> show(
    BuildContext context, {
    required Payment payment,
    required MemberLedger ledger,
  }) async {
    final wantsToVoid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PaymentDetailSheet(payment: payment, ledger: ledger),
    );

    return wantsToVoid ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.paymentDetailTitle(
                PaymentFormats.monthWithYear(payment.month),
              ),
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(ledger.member.fullName, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            SummaryTable(rows: _rows()),
            const SizedBox(height: AppSpacing.lg),
            const _VoidAction(),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.closeAction),
            ),
          ],
        ),
      ),
    );
  }

  List<SummaryRow> _rows() {
    return [
      SummaryRow(
        AppStrings.paymentDetailAmount,
        DisplayFormats.pesos(payment.amountCents),
      ),
      SummaryRow(
        AppStrings.paymentDetailMethod,
        PaymentFormats.method(payment.method),
      ),
      SummaryRow(
        AppStrings.paymentDetailPayer,
        PaymentHistoryTile.payerLabelOf(payment, ledger),
      ),
      SummaryRow(
        AppStrings.paymentDetailRecordedOn,
        PaymentFormats.day(payment.paidAt),
      ),
    ];
  }
}

class _VoidAction extends StatelessWidget {
  const _VoidAction();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).pop(true),
      icon: const Icon(Icons.block_rounded),
      label: const Text(AppStrings.paymentDetailVoidAction),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.dangerText,
        side: const BorderSide(color: AppColors.dangerText),
        minimumSize: const Size.fromHeight(52),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }
}
