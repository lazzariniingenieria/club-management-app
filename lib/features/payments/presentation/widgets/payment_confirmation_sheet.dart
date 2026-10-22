import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/payment_form.dart';
import '../formatting/payment_formats.dart';
import 'payment_notice.dart';
import 'payment_secondary_button.dart';
import 'payment_summary_table.dart';

class PaymentConfirmationSheet extends StatelessWidget {
  final PaymentForm form;

  const PaymentConfirmationSheet({super.key, required this.form});

  static Future<bool> show(BuildContext context, PaymentForm form) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PaymentConfirmationSheet(form: form),
    );

    return confirmed ?? false;
  }

  String get _total => PaymentFormats.pesos(form.totalCents);

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
              AppStrings.confirmPaymentTitle,
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            PaymentSummaryTable(rows: _rows(), total: _totalRow()),
            const SizedBox(height: AppSpacing.lg),
            const PaymentNotice(
              title: AppStrings.confirmPaymentNoticeTitle,
              message: AppStrings.confirmPaymentNotice,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ConfirmButton(
              label: AppStrings.confirmPaymentAction(_total),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            PaymentSecondaryButton(
              label: AppStrings.confirmPaymentBackAction,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }

  List<PaymentSummaryRow> _rows() {
    final member = form.ledger.member;

    return [
      PaymentSummaryRow(
        AppStrings.confirmPaymentMember,
        '${member.fullName}\n'
        '${AppStrings.memberDni(PaymentFormats.dni(member.dni))}',
      ),
      PaymentSummaryRow(
        AppStrings.confirmPaymentMonths,
        PaymentFormats.monthsSummary(form.selectedMonths),
      ),
      PaymentSummaryRow(
        AppStrings.confirmPaymentAmount,
        PaymentFormats.pesos(form.amountCents ?? 0),
      ),
      PaymentSummaryRow(
        AppStrings.confirmPaymentMethod,
        PaymentFormats.method(form.method),
      ),
      PaymentSummaryRow(AppStrings.confirmPaymentPayer, _payerName()),
    ];
  }

  PaymentSummaryRow _totalRow() {
    return PaymentSummaryRow(
      AppStrings.confirmPaymentTotal(
        AppStrings.monthCount(form.selectedMonths.length),
      ),
      _total,
    );
  }

  String _payerName() {
    final payerId = form.payerId;
    final ledger = form.ledger;
    if (payerId == null) {
      return AppStrings.paymentPayerMember(ledger.member.fullName);
    }

    return AppStrings.paymentPayerRelative(
      ledger.nameOf(payerId) ?? AppStrings.paymentPaidByUnknownRelative,
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ConfirmButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.check_rounded),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandGreen,
        foregroundColor: AppColors.textOnDark,
      ),
    );
  }
}
