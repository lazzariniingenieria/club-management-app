import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/member_ledger.dart';
import '../../domain/entities/payment.dart';
import '../formatting/payment_formats.dart';
import 'payment_pill.dart';

class PaymentHistoryTile extends StatelessWidget {
  final Payment payment;
  final MemberLedger ledger;
  final bool isNew;
  final VoidCallback onOpen;

  const PaymentHistoryTile({
    super.key,
    required this.payment,
    required this.ledger,
    required this.onOpen,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    if (payment.isVoided) return _VoidedPaymentTile(payment: payment);

    return Semantics(
      button: true,
      label: AppStrings.paymentRowSemantics(
        PaymentFormats.monthWithYear(payment.month),
        PaymentFormats.pesos(payment.amountCents),
      ),
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onOpen,
          borderRadius: AppRadius.mdAll,
          child: _LivePaymentContent(
            payment: payment,
            payer: payerLabelOf(payment, ledger),
            isNew: isNew,
          ),
        ),
      ),
    );
  }

  static String payerLabelOf(Payment payment, MemberLedger ledger) {
    if (!payment.wasPaidByAnotherMember) {
      return AppStrings.paymentPayerMember(ledger.member.fullName);
    }

    final relative = ledger.nameOf(payment.paidByMemberId!);
    if (relative == null) return AppStrings.paymentPaidByUnknownRelative;

    return AppStrings.paymentPayerRelative(relative);
  }
}

class _LivePaymentContent extends StatelessWidget {
  final Payment payment;
  final String payer;
  final bool isNew;

  const _LivePaymentContent({
    required this.payment,
    required this.payer,
    required this.isNew,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: _LivePaymentLines(
              payment: payment,
              payer: payer,
              isNew: isNew,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            PaymentFormats.pesos(payment.amountCents),
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _LivePaymentLines extends StatelessWidget {
  final Payment payment;
  final String payer;
  final bool isNew;

  const _LivePaymentLines({
    required this.payment,
    required this.payer,
    required this.isNew,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              PaymentFormats.monthTitle(payment.month),
              style: AppTextStyles.labelLarge,
            ),
            if (isNew)
              const PaymentPill(
                label: AppStrings.ledgerNewTag,
                tone: PaymentPillTone.highlight,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.paymentMethodAndDay(
            PaymentFormats.method(payment.method),
            PaymentFormats.day(payment.paidAt),
          ),
          style: AppTextStyles.bodyMedium,
        ),
        Text(AppStrings.paymentPaidBy(payer), style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

class _VoidedPaymentTile extends StatelessWidget {
  final Payment payment;

  const _VoidedPaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.disabledText),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _VoidedLines(payment: payment)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            PaymentFormats.pesos(payment.amountCents),
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoidedLines extends StatelessWidget {
  final Payment payment;

  const _VoidedLines({required this.payment});

  @override
  Widget build(BuildContext context) {
    final reason = payment.voidReason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              PaymentFormats.monthTitle(payment.month),
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const PaymentPill(
              label: AppStrings.paymentVoidedTag,
              tone: PaymentPillTone.neutral,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.paymentVoidedOn(PaymentFormats.day(payment.voidedAt!)),
          style: AppTextStyles.bodyMedium,
        ),
        Text(
          AppStrings.paymentVoidReason(
            reason ?? AppStrings.paymentVoidNoReason,
          ),
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}
